#!/bin/bash

BASE_DIR=/root/tripleo
IMAGES_DIR=../$BASE_DIR/images/
RC_FILE=$BASE_DIR/overcloudrc
TOPOLOGY_FILE=$BASE_DIR/1compute3controller.yaml
NETWORK_ISOLATION=/usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml
NETWORK_ENVIRONMENT=$BASE_DIR/network-environment.yaml
STORAGE_ENVIRONMENT=$BASE_DIR/storage-environment.yaml
ENABLE_TLS=$BASE_DIR/enable-tls.yaml
INJECT_TRUST_ANCHOR=$BASE_DIR/inject-trust-anchor.yaml
FIXED_IPS=$BASE_DIR/fixed-ips.yaml

# Log cleaning 
rm -rf /var/log/nova/*
rm -rf /var/log/neutron/*
rm -rf /var/log/ironic/*
rm -rf /var/log/mistral/*
rm -rf /var/log/ceilometer/*
rm -rf /var/log/glance/*
rm -rf /var/log/heat/*
rm -rf /var/log/httpd/*
rm -rf /var/log/rabbit/*
rm -rf /var/log/swift/*
rm -rf /var/log/ironic-inspector/*

# Deploy
time openstack overcloud deploy --templates \
    -e $TOPOLOGY_FILE \
    -e $NETWORK_ISOLATION \
    -e $NETWORK_ENVIRONMENT \
    -e $STORAGE_ENVIRONMENT \
    -e timezone.yaml \
    --verbose \
    --ntp-server pool.ntp.org


#    -e $FIXED_IPS \
#    -e $ENABLE_TLS \
#    -e $INJECT_TRUST_ANCHOR \



DEPLOYMENT_RESULT=$?

function init_openstack() {
    sleep 10
    source $RC_FILE
    openstack stack list | grep -i complete
    STACK_COMPLETE=$?
    if [[ $DEPLOYMENT_RESULT -eq 0 ]] && [[ $STACK_COMPLETE -eq 0 ]]; then

        glance image-create --name "centos" --visibility public --disk-format qcow2 --container-format bare --progress --file $IMAGES_DIR/CentOS-7-x86_64-GenericCloud.qcow2
        #glance image-create --name "cirros" --is-public true --disk-format qcow2 --container-format bare --progress --file $IMAGES_DIR/cirros-0.3.5-x86_64-disk.img
      
        nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
        nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
        nova secgroup-add-rule default tcp 80 80 0.0.0.0/0
        nova secgroup-add-rule default tcp 443 443 0.0.0.0/0
        nova keypair-add --pub-key /root/.ssh/id_rsa.pub mykey

        neutron net-create private-net --provider:network_type vxlan
        subnet="10.0.0"
        neutron subnet-create private-net --dns-nameserver 8.8.8.8 --enable-dhcp --allocation-pool start=$subnet.60,end=$subnet.100 --gateway $subnet.1 $subnet.0/24 --name private-subnet

        neutron net-create --router:external --provider:network_type flat --provider:physical_network datacentre public
        subnet="192.168.4"
        neutron subnet-create public --dns-nameserver $subnet.5 --enable-dhcp --allocation-pool start=$subnet.160,end=$subnet.200 --gateway $subnet.1 $subnet.0/24 --name public-subnet

        neutron router-create external-router
        neutron router-interface-add external-router private-subnet
        neutron router-gateway-set external-router public # openstack neutron create subnet

        openstack flavor create m1.small --id 1 --ram 512 --disk 10 --vcpus 1

        nova boot --image centos --flavor m1.small --security-groups default --key-name mykey --nic net-id= myvm

        nova floating-ip-create
        fip=`nova floating-ip-list| grep public | awk '{print $4}' | head -1`
        nova floating-ip-associate myvm $fip


    else
        echo "Something is not right, exiting!"
    fi
}
init_openstack
