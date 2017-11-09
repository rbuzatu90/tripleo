#!/bin/bash
mkdir -p /var/lib/nova/instances
chown nova:nova /var/lib/nova/instances
echo "${NOVA_NFS_EXPORT} /var/lib/nova/instances nfs rw,sync,context=system_u:object_r:nova_var_lib_t:s0 0 2" >> /etc/fstab
mount -a
