#!/bin/bash

DISK_LOCATION=/var/lib/libvirt/images
NAME=undercloud

qemu-img create -f qcow2 $DISK_LOCATION/undercloud.qcow2 120G
LIBGUESTFS_BACKEND=direct
virt-resize --expand /dev/sda1 /usr/share/rhel-guest-image-7/rhel-guest-image-* $DISK_LOCATION/$NAME.qcow2
virt-customize -a $DISK_LOCATION/$NAME.qcow2 --root-password password:mypasswd
virt-customize -a $DISK_LOCATION/$NAME.qcow2 --run-command 'systemctl disable cloud-init;systemctl disable cloud-init-local;systemctl disable cloud-config;systemctl disable cloud-final'
virt-install -n $NAME \
   --memory 1024 \
   --vcpus 1 \
   --disk path=$DISK_LOCATION/$NAME.qcow2,bus=virtio,sparse=false,cache=none,io=native \
   --network network=default,model=virtio \
   --graphics vnc \
   --print-xml >> $NAME.xml

virsh attach-interface --domain $NAME --model virtio --config --live --type bridge --source br-ex
