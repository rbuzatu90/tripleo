#!/bin/bash
mkdir -p /var/lib/glance/images
chown glance:glance /var/lib/glance/images
echo "${GLANCE_NFS_EXPORT} /var/lib/glance/images nfs rw,sync 0 2" >> /etc/fstab
mount -a
