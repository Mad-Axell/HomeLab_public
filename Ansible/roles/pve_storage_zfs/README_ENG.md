# pve_storage_zfs

The role reproduces host-specific ZFS storage from stable
`/dev/disk/by-id` paths. It uses `community.general.zfs` for datasets and
`community.general.zpool_facts` for health checks. An `ansible.builtin.command`
task is used only for initial `zpool create`, because the installed collection
does not provide a pool-creation module.

Pool creation is blocked unless both values are supplied:

```yaml
pve_storage_zfs_apply: true
pve_storage_zfs_apply_confirmation: CREATE_PVE_ZFS_POOLS
```

Review every device path before enabling apply. Creating a pool can destroy
existing data. Existing pools are never recreated. Dataset and permission
changes also run only when `pve_storage_zfs_apply` is true.

## Verification of existing pools

Because the role only ever creates *absent* pools, a pool that was built
differently from its declaration would otherwise stay invisible: it exists, it
is `ONLINE`, and every run converges green over the defect. Three read-only
checks close that gap. They also run under `--check`, before anything is applied.

| Check | What it catches | Why only a rebuild fixes it |
|-------|-----------------|-----------------------------|
| Topology | The pool has a different shape than declared | ZFS cannot convert a pool between topologies in place |
| Membership | The right shape on the wrong disks, or a pool built from `/dev/sdX` | The declaration no longer describes the hardware |
| `ashift` | The pool was created with the wrong sector size | `ashift` is fixed when a vdev is created, forever |

Topology is read from `zpool list -vH`. That output indents top-level vdevs and
their leaf devices with the same single tab, so the levels cannot be told apart
by indentation; a redundancy group is recognised by its `<type>-<index>` name,
and children without such a name mean a bare stripe. Single-parity raidz is
reported as `raidz1` but declared as `raidz`, so the expected value is mapped
before comparison.

Dataset properties are deliberately not on this list: `community.general.zfs`
applies the declared properties on every run, so they converge on their own.

## Declare every locally set property

The declaration must list **every** property the pool sets locally, not only the
interesting ones. The role applies exactly what it is given, so a property that
exists only on disk is silently lost the moment the pool is recreated. Audit
with:

```bash
zfs get -o name,property,value,source -s local,received all <pool>
```

Two pairings are worth knowing. `xattr=on` is equal to `sa` on current OpenZFS,
not to directory-based xattrs, and it needs `dnodesize=auto` to be useful: with
the legacy 512-byte dnode, extended attributes no longer fit in the
system-attribute area and spill into directory-based storage, which is the cost
`sa` exists to avoid. This matters wherever Samba stores DOS attributes and NT
ACLs, or SELinux stores labels.
