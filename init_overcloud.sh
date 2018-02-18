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

source $UNDERCLOUD_RC_FILE

openstack stack list | grep -i complete
STACK_COMPLETE=$?
echo "Stack complete is $STACK_COMPLETE and deployment exited with $DEPLOYMENT_RESULT"
if [[ $DEPLOYMENT_RESULT -eq 0 ]] && [[ $STACK_COMPLETE -eq 0 ]]; then
    source $OVERCLOUD_RC_FILE
    glance image-create --name "centos" --visibility public --disk-format qcow2 --container-format bare --progress --file $IMAGES_DIR/CentOS-7-x86_64-GenericCloud.qcow2
    #glance image-create --name "cirros" --is-public true --disk-format qcow2 --container-format bare --progress --file $IMAGES_DIR/cirros-0.3.5-x86_64-disk.img

    nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
    nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
    nova secgroup-add-rule default tcp 80 80 0.0.0.0/0
    nova secgroup-add-rule default tcp 443 443 0.0.0.0/0
    nova keypair-add --pub-key /root/.ssh/id_rsa.pub mykey

    openstack flavor create m1.small --id 1 --ram 512 --disk 9 --vcpus 1

    neutron net-create private-net --provider:network_type vxlan
    subnet="10.0.0"
    neutron subnet-create private-net --dns-nameserver 8.8.8.8 --enable-dhcp --allocation-pool start=$subnet.60,end=$subnet.100 --gateway $subnet.1 $subnet.0/24 --name private-subnet

    neutron net-create --router:external --provider:network_type flat --provider:physical_network datacentre public-net
    subnet="192.168.122"
    neutron subnet-create public-net --dns-nameserver $subnet.5 --enable-dhcp --allocation-pool start=$subnet.160,end=$subnet.200 --gateway $subnet.1 $subnet.0/24 --name public-subnet

    neutron router-create external-router
    neutron router-interface-add external-router private-subnet
    neutron router-gateway-set external-router public-net

    net_id=`neutron net-list  | grep private |awk '{print $2}'`
    nova boot --image centos --flavor m1.small --security-groups default --key-name mykey --nic net-id=$net_id myvm

    nova floating-ip-create public-net
    fip=`nova floating-ip-list| grep public | awk '{print $4}' | head -1`
    sleep 5
    nova floating-ip-associate myvm $fip
    nova list
    echo "Init overcloud done"
else
    echo "Something is not right, exiting!"
fi

