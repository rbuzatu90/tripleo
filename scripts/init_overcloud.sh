#!/bin/bash

set +x

BASE_DIR=/home/stack/tripleo
IMAGES_DIR=$BASE_DIR/../images/
UNDERCLOUD_RC_FILE=$BASE_DIR/../stackrc
OVERCLOUD_RC_FILE=$BASE_DIR/../overcloudrc.v3
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
    glance image-create --name "rhel7" --visibility public --disk-format qcow2 --container-format bare --progress --file $IMAGES_DIR/rhel-server-7.7-update-1-x86_64-kvm.qcow2
    # set password for centos image; add public key, install tcpdump nmap wget
    # lower DHCP timeout on image virt-customize -a CentOS-7-x86_64-GenericCloud.qcow2 --run-command 'echo -e "timeout 20;\nretry 10;" > /etc/dhcp/dhclient.conf'
    #glance image-create --name "cirros" --is-public true --disk-format qcow2 --container-format bare --progress --file $IMAGES_DIR/cirros-0.3.5-x86_64-disk.img
    
    for i in `openstack security group list -c ID -f csv | grep -v ID | tr -d '"'`; do
        openstack security group rule create --protocol icmp $i
        openstack security group rule create  --dst-port 1:65000 $i
    done

    openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey

    openstack flavor create m1.small --id auto --ram 1024 --disk 30 --vcpus 2

    neutron net-create private-net --provider:network_type vxlan
    subnet="10.0.0"
    neutron subnet-create private-net --dns-nameserver 8.8.8.8 --enable-dhcp --allocation-pool start=$subnet.60,end=$subnet.100 --gateway $subnet.1 $subnet.0/24 --name private-subnet

    neutron net-create --router:external --provider:network_type flat --provider:physical_network datacentre public-net
    subnet="192.168.122"
    neutron subnet-create public-net --dns-nameserver $subnet.5 --enable-dhcp --allocation-pool start=$subnet.160,end=$subnet.200 --gateway $subnet.1 $subnet.0/24 --name public-subnet

    neutron router-create external-router
    neutron router-interface-add external-router private-subnet
    neutron router-gateway-set external-router public-net
    secgrp=`openstack security group list --project admin -c ID -f value`
    netid=`openstack network list --internal  | grep private | awk '{print $2}'`
    vmid1=`openstack server create --image centos --flavor m1.small --security-group $secgrp --key-name mykey --nic net-id=$netid vm1 -c id -f value`
    vmid2=`openstack server create --image centos --flavor m1.small --security-group $secgrp --key-name mykey --nic net-id=$netid vm2 -c id -f value`
    pubnetid=`openstack network list --external -c ID -f value`
    fip1=`openstack floating ip create $pubnetid -c floating_ip_address -f value`
    fip2=`openstack floating ip create $pubnetid -c floating_ip_address -f value`
    openstack server add floating ip $vmid1 $fip1
    openstack server add floating ip $vmid2 $fip2

    sleep 10
    ping -c2 $fip1
    ping -c2 $fip2
    nova list
    echo "Init overcloud done"
else
    echo "Something is not right, exiting!"
fi

