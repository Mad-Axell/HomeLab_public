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
