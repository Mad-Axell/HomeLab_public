#!/usr/bin/python
# -*- coding: utf-8 -*-

from __future__ import absolute_import, division, print_function

__metaclass__ = type

DOCUMENTATION = r'''
---
module: mikrotik_swos_config
short_description: Reconcile MikroTik SwOS configuration with safety gates
description:
  - Validates a CSS326 switch before changing it.
  - Creates a controller-side binary backup before real drift remediation.
  - Applies VLAN table, per-port VLAN, Link, and System settings in that order.
options:
  host:
    type: str
    required: true
  username:
    type: str
    default: admin
  password:
    type: str
    required: true
  expected_model:
    type: str
    required: true
  expected_version:
    type: str
    required: true
  expected_port_count:
    type: int
    required: true
  configuration:
    type: dict
    required: true
  backup_directory:
    type: path
    required: true
  allow_network_changes:
    type: bool
    default: false
  recovery_access_confirmed:
    type: bool
    default: false
author:
  - HomeLab maintainers
'''

EXAMPLES = r'''
- name: Reconcile a CSS326 switch
  mikrotik_swos_config:
    host: 192.0.2.10
    username: admin
    password: "{{ vault_switch_password }}"
    expected_model: CSS326-24G-2S+
    expected_version: "2.18"
    expected_port_count: 26
    configuration: "{{ switch_configuration }}"
    backup_directory: /var/backups/mikrotik-swos
    allow_network_changes: true
    recovery_access_confirmed: true
'''

RETURN = r'''
backup_created:
  description: Whether a pre-change .swb backup was created.
  type: bool
  returned: always
changed_sections:
  description: Configuration sections that differed before reconciliation.
  type: list
  elements: str
  returned: always
model:
  description: Detected switch model.
  type: str
  returned: always
version:
  description: Detected SwOS version.
  type: str
  returned: always
port_count:
  description: Detected port count.
  type: int
  returned: always
'''

import datetime
import ipaddress
import os
import re

from ansible.module_utils.basic import AnsibleModule

try:
    from swos import (
        get_backup,
        get_links,
        get_port_vlans,
        get_system_info,
        get_vlans,
        set_port_config,
        set_port_vlan,
        set_system,
        set_vlans,
    )

    HAS_SWOS = True
    SWOS_IMPORT_ERROR = None
except ImportError as import_error:
    HAS_SWOS = False
    SWOS_IMPORT_ERROR = import_error


SYSTEM_KEYS = {
    "identity",
    "address_acquisition",
    "static_ip",
    "allow_from",
    "allow_from_ports",
    "allow_from_vlan",
}
PORT_KEYS = {"port", "enabled", "name", "auto_negotiation"}
PORT_VLAN_KEYS = {
    "port",
    "vlan_mode",
    "vlan_receive",
    "default_vlan_id",
    "force_vlan_id",
}
VLAN_KEYS = {
    "vlan_id",
    "member_ports",
    "igmp_snooping",
    "name",
    "isolation",
    "learning",
    "mirror",
}
VLAN_MODES = {"Disabled", "Optional", "Enabled", "Strict"}
VLAN_RECEIVE_MODES = {"Any", "Only Tagged", "Only Untagged"}


def _required_keys(value, keys, label):
    missing = sorted(keys - set(value))
    if missing:
        raise ValueError("%s is missing required keys: %s" % (label, ", ".join(missing)))


def _reject_unknown_keys(value, keys, label):
    unknown = sorted(set(value) - keys)
    if unknown:
        raise ValueError("%s contains unsupported keys: %s" % (label, ", ".join(unknown)))


def _validate_port_number(port_number, port_count, label):
    if isinstance(port_number, bool) or not isinstance(port_number, int):
        raise ValueError("%s port must be an integer" % label)
    if port_number < 1 or port_number > port_count:
        raise ValueError("%s port must be between 1 and %d" % (label, port_count))


def _validate_configuration(configuration, port_count):
    if not isinstance(configuration, dict):
        raise ValueError("configuration must be a dictionary")
    _required_keys(configuration, {"system", "ports", "port_vlans", "vlans"}, "configuration")
    _reject_unknown_keys(configuration, {"system", "ports", "port_vlans", "vlans"}, "configuration")

    system = configuration["system"]
    if not isinstance(system, dict):
        raise ValueError("configuration.system must be a dictionary")
    _required_keys(system, SYSTEM_KEYS, "configuration.system")
    _reject_unknown_keys(system, SYSTEM_KEYS, "configuration.system")
    if not isinstance(system["identity"], str) or not system["identity"].strip():
        raise ValueError("configuration.system.identity must be a non-empty string")
    if system["address_acquisition"] != "static":
        raise ValueError("configuration.system.address_acquisition must be 'static'")
    ipaddress.ip_address(system["static_ip"])
    ipaddress.ip_network(system["allow_from"], strict=False)
    if not isinstance(system["allow_from_ports"], list):
        raise ValueError("configuration.system.allow_from_ports must be a list")
    if len(system["allow_from_ports"]) != len(set(system["allow_from_ports"])):
        raise ValueError("configuration.system.allow_from_ports contains duplicates")
    for port_number in system["allow_from_ports"]:
        _validate_port_number(port_number, port_count, "configuration.system.allow_from_ports")
    if isinstance(system["allow_from_vlan"], bool) or not isinstance(system["allow_from_vlan"], int):
        raise ValueError("configuration.system.allow_from_vlan must be an integer")
    if system["allow_from_vlan"] < 1 or system["allow_from_vlan"] > 4095:
        raise ValueError("configuration.system.allow_from_vlan must be between 1 and 4095")

    ports = configuration["ports"]
    if not isinstance(ports, list):
        raise ValueError("configuration.ports must be a list")
    port_numbers = []
    for item in ports:
        if not isinstance(item, dict):
            raise ValueError("each configuration.ports item must be a dictionary")
        _required_keys(item, {"port", "enabled"}, "configuration.ports item")
        _reject_unknown_keys(item, PORT_KEYS, "configuration.ports item")
        _validate_port_number(item["port"], port_count, "configuration.ports item")
        if not isinstance(item["enabled"], bool):
            raise ValueError("configuration.ports enabled must be a boolean")
        port_numbers.append(item["port"])
    if sorted(port_numbers) != list(range(1, port_count + 1)):
        raise ValueError("configuration.ports must define every port exactly once")

    port_vlans = configuration["port_vlans"]
    if not isinstance(port_vlans, list):
        raise ValueError("configuration.port_vlans must be a list")
    port_vlan_numbers = []
    for item in port_vlans:
        if not isinstance(item, dict):
            raise ValueError("each configuration.port_vlans item must be a dictionary")
        _required_keys(item, {"port", "vlan_mode", "default_vlan_id"}, "configuration.port_vlans item")
        _reject_unknown_keys(item, PORT_VLAN_KEYS, "configuration.port_vlans item")
        _validate_port_number(item["port"], port_count, "configuration.port_vlans item")
        if item["vlan_mode"] not in VLAN_MODES:
            raise ValueError("configuration.port_vlans contains an unsupported vlan_mode")
        if "vlan_receive" in item and item["vlan_receive"] not in VLAN_RECEIVE_MODES:
            raise ValueError("configuration.port_vlans contains an unsupported vlan_receive")
        if isinstance(item["default_vlan_id"], bool) or not isinstance(item["default_vlan_id"], int):
            raise ValueError("configuration.port_vlans default_vlan_id must be an integer")
        if item["default_vlan_id"] < 1 or item["default_vlan_id"] > 4094:
            raise ValueError("configuration.port_vlans default_vlan_id must be between 1 and 4094")
        if "force_vlan_id" in item and not isinstance(item["force_vlan_id"], bool):
            raise ValueError("configuration.port_vlans force_vlan_id must be a boolean")
        port_vlan_numbers.append(item["port"])
    if sorted(port_vlan_numbers) != list(range(1, port_count + 1)):
        raise ValueError("configuration.port_vlans must define every port exactly once")

    vlans = configuration["vlans"]
    if not isinstance(vlans, list) or not vlans:
        raise ValueError("configuration.vlans must be a non-empty list")
    vlan_ids = []
    for item in vlans:
        if not isinstance(item, dict):
            raise ValueError("each configuration.vlans item must be a dictionary")
        _required_keys(item, {"vlan_id", "member_ports"}, "configuration.vlans item")
        _reject_unknown_keys(item, VLAN_KEYS, "configuration.vlans item")
        vlan_id = item["vlan_id"]
        if isinstance(vlan_id, bool) or not isinstance(vlan_id, int) or vlan_id < 1 or vlan_id > 4094:
            raise ValueError("configuration.vlans vlan_id must be between 1 and 4094")
        if not isinstance(item["member_ports"], list):
            raise ValueError("configuration.vlans member_ports must be a list")
        if len(item["member_ports"]) != len(set(item["member_ports"])):
            raise ValueError("configuration.vlans member_ports contains duplicates")
        for port_number in item["member_ports"]:
            _validate_port_number(port_number, port_count, "configuration.vlans member_ports")
        vlan_ids.append(vlan_id)
    if len(vlan_ids) != len(set(vlan_ids)):
        raise ValueError("configuration.vlans contains duplicate VLAN IDs")


def _index_by(items, key):
    return {item[key]: item for item in items}


def _system_matches(current, desired):
    for key, desired_value in desired.items():
        current_value = current.get(key)
        if key == "allow_from_ports":
            if sorted(current_value or []) != sorted(desired_value):
                return False
        elif current_value != desired_value:
            return False
    return True


def _port_matches(current, desired):
    key_map = {
        "enabled": "enabled",
        "name": "port_name",
        "auto_negotiation": "auto_negotiation",
    }
    for desired_key, current_key in key_map.items():
        if desired_key in desired and current.get(current_key) != desired[desired_key]:
            return False
    return True


def _port_vlan_matches(current, desired):
    for key in ("vlan_mode", "vlan_receive", "default_vlan_id", "force_vlan_id"):
        if key in desired and current.get(key) != desired[key]:
            return False
    return True


def _vlan_matches(current, desired):
    if sorted(current.get("member_ports", [])) != sorted(desired["member_ports"]):
        return False
    if current.get("igmp_snooping", False) != desired.get("igmp_snooping", False):
        return False
    for key in ("name", "isolation", "learning", "mirror"):
        if key in desired and current.get(key) != desired[key]:
            return False
    return True


def _vlans_match(current_items, desired_items):
    current = _index_by(current_items, "vlan_id")
    desired = _index_by(desired_items, "vlan_id")
    if set(current) != set(desired):
        return False
    return all(_vlan_matches(current[vlan_id], item) for vlan_id, item in desired.items())


def _read_state(url, username, password):
    return {
        "system": get_system_info(url, username, password),
        "ports": get_links(url, username, password),
        "port_vlans": get_port_vlans(url, username, password),
        "vlans": get_vlans(url, username, password),
    }


def _validate_device(state, expected_model, expected_version, expected_port_count):
    system = state["system"]
    if system.get("model") != expected_model:
        raise ValueError("unexpected switch model")
    if system.get("version") != expected_version:
        raise ValueError("unexpected SwOS version")
    if len(state["ports"]) != expected_port_count:
        raise ValueError("unexpected Link port count")
    if len(state["port_vlans"]) != expected_port_count:
        raise ValueError("unexpected VLAN port count")


def _changed_sections(state, desired):
    changed = []
    if not _vlans_match(state["vlans"], desired["vlans"]):
        changed.append("vlans")

    current_port_vlans = _index_by(state["port_vlans"], "port_number")
    if any(not _port_vlan_matches(current_port_vlans[item["port"]], item) for item in desired["port_vlans"]):
        changed.append("port_vlans")

    current_ports = _index_by(state["ports"], "port_number")
    if any(not _port_matches(current_ports[item["port"]], item) for item in desired["ports"]):
        changed.append("ports")

    if not _system_matches(state["system"], desired["system"]):
        changed.append("system")
    return changed


def _write_backup(backup_directory, identity, backup_data):
    if not backup_data:
        raise ValueError("switch returned an empty backup")
    os.makedirs(backup_directory, mode=0o700, exist_ok=True)
    os.chmod(backup_directory, 0o700)
    safe_identity = re.sub(r"[^a-zA-Z0-9_.-]", "_", identity)
    timestamp = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%S%fZ")
    backup_path = os.path.join(backup_directory, "%s_%s.swb" % (safe_identity, timestamp))
    file_descriptor = os.open(backup_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(file_descriptor, "wb") as backup_file:
        backup_file.write(backup_data)
    return backup_path


def _apply_configuration(url, username, password, state, desired, changed_sections):
    if "vlans" in changed_sections:
        set_vlans(url, username, password, desired["vlans"])

    if "port_vlans" in changed_sections:
        current = _index_by(state["port_vlans"], "port_number")
        for item in desired["port_vlans"]:
            if not _port_vlan_matches(current[item["port"]], item):
                set_port_vlan(
                    url,
                    username,
                    password,
                    item["port"],
                    vlan_mode=item.get("vlan_mode"),
                    vlan_receive=item.get("vlan_receive"),
                    default_vlan_id=item.get("default_vlan_id"),
                    force_vlan_id=item.get("force_vlan_id"),
                )

    if "ports" in changed_sections:
        current = _index_by(state["ports"], "port_number")
        for item in desired["ports"]:
            if not _port_matches(current[item["port"]], item):
                set_port_config(
                    url,
                    username,
                    password,
                    item["port"],
                    name=item.get("name"),
                    enabled=item.get("enabled"),
                    auto_negotiation=item.get("auto_negotiation"),
                )

    if "system" in changed_sections:
        system = desired["system"]
        set_system(
            url,
            username,
            password,
            identity=system.get("identity"),
            address_acquisition=system.get("address_acquisition"),
            static_ip=system.get("static_ip"),
            allow_from=system.get("allow_from"),
            allow_from_ports=system.get("allow_from_ports"),
            allow_from_vlan=system.get("allow_from_vlan"),
        )


def run_module():
    module = AnsibleModule(
        argument_spec={
            "host": {"type": "str", "required": True},
            "username": {"type": "str", "default": "admin"},
            "password": {"type": "str", "required": True, "no_log": True},
            "expected_model": {"type": "str", "required": True},
            "expected_version": {"type": "str", "required": True},
            "expected_port_count": {"type": "int", "required": True},
            "configuration": {"type": "dict", "required": True},
            "backup_directory": {"type": "path", "required": True},
            "allow_network_changes": {"type": "bool", "default": False},
            "recovery_access_confirmed": {"type": "bool", "default": False},
        },
        supports_check_mode=True,
    )

    if not HAS_SWOS:
        module.fail_json(
            msg="mikrotik-swos is required on the Ansible controller: %s" % SWOS_IMPORT_ERROR,
            changed=False,
        )

    host = module.params["host"]
    url = host if host.startswith(("http://", "https://")) else "http://%s" % host
    username = module.params["username"]
    password = module.params["password"]
    expected_model = module.params["expected_model"]
    expected_version = module.params["expected_version"]
    expected_port_count = module.params["expected_port_count"]
    desired = module.params["configuration"]

    result = {
        "changed": False,
        "backup_created": False,
        "changed_sections": [],
        "model": None,
        "version": None,
        "port_count": None,
    }

    try:
        _validate_configuration(desired, expected_port_count)
        state = _read_state(url, username, password)
        _validate_device(state, expected_model, expected_version, expected_port_count)
        result["model"] = state["system"].get("model")
        result["version"] = state["system"].get("version")
        result["port_count"] = len(state["ports"])
        result["changed_sections"] = _changed_sections(state, desired)
        result["changed"] = bool(result["changed_sections"])

        if not result["changed"] or module.check_mode:
            module.exit_json(**result)

        if not module.params["allow_network_changes"]:
            module.fail_json(msg="real network changes are not allowed", **result)
        if not module.params["recovery_access_confirmed"]:
            module.fail_json(msg="physical recovery access is not confirmed", **result)

        backup_data = get_backup(url, username, password)
        result["backup_file"] = _write_backup(
            module.params["backup_directory"],
            desired["system"]["identity"],
            backup_data,
        )
        result["backup_created"] = True

        _apply_configuration(url, username, password, state, desired, result["changed_sections"])

        final_state = _read_state(url, username, password)
        _validate_device(final_state, expected_model, expected_version, expected_port_count)
        remaining_drift = _changed_sections(final_state, desired)
        if remaining_drift:
            module.fail_json(
                msg="configuration verification failed after apply",
                remaining_drift=remaining_drift,
                **result
            )
        module.exit_json(**result)
    except Exception as error:
        module.fail_json(msg="SwOS reconciliation failed: %s" % error, **result)


def main():
    run_module()


if __name__ == "__main__":
    main()
