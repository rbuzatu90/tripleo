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


sudo subscription-manager register --username=rbuzatu@redhat.com
pool=$(sudo subscription-manager list --available | grep -v "^ " | grep -m1 -A 5 "Employee SKU" | grep Pool | awk '{print $3}')
sudo subscription-manager attach --pool=$pool
sudo subscription-manager repos --disable=*
sudo subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-extras-rpms --enable=rhel-7-server-rh-common-rpms --enable=rhel-ha-for-rhel-7-server-rpms --enable=rhel-7-server-openstack-13-rpms --enable=rhel-7-server-rhceph-3-tools-rpms
sudo yum update -y
sudo yum install -y python-tripleoclient rhosp-director-images rhosp-director-images-ipa vim telnet wget tcpdump nmap tmux git crudini jq bind-utils net-tools yum-utils libguestfs-tools bash-completion bash-completion-extras
reboot

useradd stack
passwd stack
echo "stack ALL=(root) NOPASSWD:ALL" | tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack
su - stack
mkdir ~/images/

source $UNDERCLOUD_RC_FILE
cd $IMAGES_DIR
for i in /usr/share/rhosp-director-images/overcloud-full-latest.tar /usr/share/rhosp-director-images/ironic-python-agent-latest.tar; do tar -xvf $i; done
# Customize overcloud img
# Set root password
# Set alias for vim
# Set undercloud hostname
# Set disable_root:0 in /etc/cloud/cloud.cfg
#export LIBGUESTFS_BACKEND=direct
#virt-customize -a overcloud-full.qcow2 --root-password password:mypasswd
#virt-customize -a overcloud-full.qcow2 --run-command 'echo "192.168.122.10 uc.mylab.test" >> /etc/hosts; echo alias vim="vi" >> /etc/profile; alias rsync="rsync --progress" >> /etc/profile; sed -i "s/disable_root.*/disable_root: 0/" /etc/cloud/cloud.cfg; sed -i "s/#UseDNS.*/UseDNS no/" /etc/ssh/sshd_config'
virt-customize -a overcloud-full.qcow2 --run-command "echo 'set completion-ignore-case on' >> /root/.inputrc; sed -i 's/^ssh_pwauth.*/ssh_pwauth: 1/' /etc/cloud/cloud.cfg; sed -i 's/^disable_root.*/disable_root: 0/' /etc/cloud/cloud.cfg; sed -i 's/#UseDNS.*/UseDNS no/' /etc/ssh/sshd_config; systemctl disable cloud-init;systemctl disable cloud-init-local;systemctl disable cloud-config;systemctl disable cloud-final" --root-password password:redhat --ssh-inject "root:string:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+aPJS2SOiakBfa5Tq1Zc1oLgM7zl9UDLqc8z0AHSlyPbp4vf09NqHUKv20JYB91aD0SS0Joz7FsXMqnwp5aNdE18NHrH+PFTCPBgsHL9sle77tdhwwj6P6JKsEYrXf+TxhmfDNcHFnaL2zNfu3CZcxGEmRtX1zi8HDiysmXEIru+dZziYM1CUdds8zkZ6IeLV6h5ASBiYv2/rcPbhZa98tgVbGyQJ0d1iSkMY0zXev6okflNx+O3Kx1HUvyPf4vh50ebQZ45gL0ZxO9vbIOPIC/8fdaUhBVZkihtpA2Afpr7wsYOSH+dMQL4WsDzd9m4Sno6mVgHBKaMb/BdIb1bH root@zion"
openstack overcloud image upload --update-existing --image-path $IMAGES_DIR
openstack subnet set --dns-nameserver 10.0.2.1 `openstack subnet list | grep ctlplane | awk '{print $2}'`


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
