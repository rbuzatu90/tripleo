#!/bin/bash

set +x

BASE_DIR=/root/tripleo
IMAGES_DIR=$BASE_DIR/../images/
UNDERCLOUD_RC_FILE=$BASE_DIR/stackrc
OVERCLOUD_RC_FILE=$BASE_DIR/overcloudrc.v3
TOPOLOGY_FILE=$BASE_DIR/1compute3controller.yaml
NETWORK_ISOLATION=/usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml
NETWORK_ENVIRONMENT=$BASE_DIR/network-environment.yaml
STORAGE_ENVIRONMENT=$BASE_DIR/storage-environment.yaml
ENABLE_TLS=$BASE_DIR/enable-tls.yaml
INJECT_TRUST_ANCHOR=$BASE_DIR/inject-trust-anchor.yaml
FIXED_IPS=$BASE_DIR/fixed-ips.yaml

useradd stack
passwd stack
echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack
su - stack
mkdir ~/images/

source $UNDERCLOUD_RC_FILE
yum install -y rhosp-director-images rhosp-director-images-ipa
cd $IMAGES_DIR
for i in /usr/share/rhosp-director-images/overcloud-full-latest-10.0.tar /usr/share/rhosp-director-images/ironic-python-agent-latest-10.0.tar; do tar -xvf $i; done
# Customize overcloud img
# Set root password
# Set alias for vim
# Set undercloud hostname
# Set disable_root:0 in /etc/cloud/cloud.cfg
yum install -y libguestfs-tools.noarch
#export LIBGUESTFS_BACKEND=direct
#virt-customize -a overcloud-full.qcow2 --root-password password:mypasswd
#virt-customize -a overcloud-full.qcow2 --run-command 'echo "192.168.122.10 uc.mylab.test" >> /etc/hosts; echo alias vim="vi" >> /etc/profile; alias rsync="rsync --progress" >> /etc/profile; sed -i "s/disable_root.*/disable_root: 0/" /etc/cloud/cloud.cfg; sed -i "s/#UseDNS.*/UseDNS no/" /etc/ssh/sshd_config'
openstack overcloud image upload --update-existing --image-path $IMAGES_DIR
openstack subnet set --dns-nameserver 8.8.8.8 <SUBNET_ID>


openstack baremetal import --json nodes.json
openstack overcloud node import nodes.json


time openstack overcloud node introspect --all-manageable --provide
#time openstack  baremetal introspection bulk start
#openstack baremetal node manage [NODE UUID]
#openstack overcloud node introspect [NODE UUID] --provide

openstack overcloud profiles list

openstack baremetal introspection data save <ironic-node> | jq ".inventory.disks"

for i in $(openstack baremetal node list -c Name -f value); do openstack baremetal node set --property root_device='{"name":"/dev/sda"}' $i; done
openstack baremetal node set --property root_device='{"serial": "61866da04f380d001ea4e13c12e36ad6"}' <ironic-node>
