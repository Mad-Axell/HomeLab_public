# go2rtc

Deploys **go2rtc** — a dedicated camera gateway — as a Docker container via
Docker Compose v2.

## What the role does

1. Validates `vault_go2rtc_config` and the port list.
2. Creates the project directory and the `config` subdirectory.
3. Renders `compose.yml` from the `Docker_Compose_Go2rtc.j2` template.
4. Writes `config/go2rtc.yaml` from `vault_go2rtc_config` (secret, no diff or
   log output).
5. Starts or updates the container through
   `community.docker.docker_compose_v2`.

## Why a dedicated container

go2rtc is bundled inside Frigate, but a dedicated instance gives:

- **one connection per camera** — detection, recording, Home Assistant live
  view and manual checks pull a single stream from go2rtc instead of four
  RTSP sessions from the camera;
- **a persistent UI on :1984** — the bundled go2rtc config inside Frigate is
  regenerated on every start, the dedicated one stays stable;
- **an independent lifecycle** — upgrades and debugging separate from Frigate.

To keep Frigate live view and birdseye, Frigate's internal go2rtc consumes
the dedicated instance as its source: `go2rtc.streams.<cam> =
rtsp://<user>:<pass>@go2rtc:8554/<stream>` — the containers share the
`go2rtc_network_name` Docker network, and the dedicated instance's
RTSP/WebRTC ports are not published on the host (avoiding a clash with
Frigate's restream on 8554/8555).

## Variables

| Variable | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `go2rtc_debug_mode` | bool | no | `false` | Enable the change summary debug. |
| `go2rtc_project_directory` | string | no | `"/opt/go2rtc"` | Compose project directory. |
| `go2rtc_image` | string | no | `"alexxit/go2rtc:1.9.15"` | Container image. |
| `go2rtc_container_name` | string | no | `"go2rtc"` | Container name. |
| `go2rtc_ports` | list | no | `["1984:1984"]` | Published ports (web UI). |
| `go2rtc_network_name` | string | no | `"cam_streams"` | Network shared with consumers (Frigate attaches it as external). |

## Secret input

| Variable | Description |
| --- | --- |
| `vault_go2rtc_config` | Complete `go2rtc.yaml` (streams with RTSP URLs and camera credentials, `rtsp:` section user/password for external consumers, `api:`, `webrtc:`). Loaded from `VARS/secrets.yml` by the playbook; the role never loads Vault files itself. |

## Requirements

- Docker Engine with compose v2 on the target host (the `docker` role here).
- `community.docker` on the controller.

## Example

```yaml
- hosts: frigate
  vars_files: [../VARS/secrets.yml]
  roles:
    - role: go2rtc
```

## Check mode limitations

`docker_compose_v2` does not apply changes in check mode; the task runs but no
container is created. Copy/template tasks behave as usual.
