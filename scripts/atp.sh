
source ~/stackrc
openstack baremetal node list # all nodes should have a valid power state (on) and maintenance mode should be false

for NODE in $(openstack server list -f value -c Networks | cut -d= -f2); do echo "=== $NODE ===" ; ssh heat-admin@$NODE "sudo systemctl list-units --state=failed 'openstack*' 'neutron*' 'httpd' 'docker' 'ceph*'" ; done # check for failed Systemd services

for NODE in $(openstack server list -f value -c Networks | cut -d= -f2); do echo "=== $NODE ===" ; ssh heat-admin@$NODE "sudo docker ps -f 'status=dead' -f 'status=restarting' -f 'health=unhealthy' -f 'health=starting' -f 'exited=1' --all" ; done # check for failed containerized services

CTRL_NAME=ctrl1; NODE=$(openstack server list --name $CTRL_NAME -f value -c Networks | cut -d= -f2); PASS=$(ssh heat-admin@$NODE sudo 'grep "listen haproxy.stats" -A 6 /var/lib/config-data/puppet-generated/haproxy/etc/haproxy/haproxy.cfg | grep "stats auth admin:" | cut -d: -f2'); IPADDR=$(ssh heat-admin@$NODE sudo 'grep "listen haproxy.stats" -A 6 /var/lib/config-data/puppet-generated/haproxy/etc/haproxy/haproxy.cfg | grep ":1993" | grep -o "[0-9.]*" | head -1'); curl -s -u admin:$PASS "http://$IPADDR:1993/;csv" | egrep -vi "(frontend|backend)" | awk -F',' '{ print $1" "$2" "$18 }' # check the HAProxy connection to all services

for NODE in $(openstack server list --name controller -f value -c Networks | cut -d= -f2); do echo "=== $NODE ===" ; ssh heat-admin@$NODE "sudo docker exec clustercheck clustercheck" ; done # check overcloud database replication health

for NODE in $(openstack server list --name controller -f value -c Networks | cut -d= -f2); do echo "=== $NODE ===" ; ssh heat-admin@$NODE "sudo docker exec $(ssh heat-admin@$NODE "sudo docker ps -f 'name=.*rabbitmq.*' -q") rabbitmqctl node_health_check" ; done # check RabbitMQ cluster health

NODE=$(openstack server list --name controller-0 -f value -c Networks | cut -d= -f2); ssh heat-admin@$NODE "sudo pcs status" # check Pacemaker resource health

for NODE in $(openstack server list -f value -c Networks | cut -d= -f2); do echo "=== $NODE ===" ; ssh heat-admin@$NODE "sudo df -h --output=source,fstype,avail -x overlay -x tmpfs -x devtmpfs" ; done # check disk usage

NODE=$(openstack server list --name controller-0 -f value -c Networks | cut -d= -f2); ssh heat-admin@$NODE "sudo ceph -s" # check ceph health

NODE=$(openstack server list --name controller-0 -f value -c Networks | cut -d= -f2); ssh heat-admin@$NODE "sudo ceph df" # check ceph space utilization 

for NODE in $(openstack server list -f value -c Networks | cut -d= -f2); do echo "=== $NODE ===" ; ssh heat-admin@$NODE "sudo ntpstat" ; done # check NTP

source ~/overcloudrc
openstack network agent list
openstack compute service list
openstack volume service list





#Run on controller
Check PCS status
Check fencing and fencing agents are having constraints
Check Ceph mapping


#contrail
subnet=10.0.1.0/24
ip1=10.0.1.10
ip2=10.0.1.11
vlan=3201
physnet=physnet1
net_name="sriov"
neutron net-create --provider:physical_network=$physnet --provider:segmentation_id=$vlan $net_name
neutron subnet-create --name $net_name-subnet $net_name $subnet
neutron port-create --fixed-ip subnet_id=`openstack subnet show $net_name-subnet -c id -f value`,ip_address=$ip1 --name $net_name-port1 `openstack network show $net_name -c id -f value` --binding:vnic_type direct
neutron port-create --fixed-ip subnet_id=`openstack subnet show $net_name-subnet -c id -f value`,ip_address=$ip2 --name $net_name-port2 `openstack network show $net_name -c id -f value` --binding:vnic_type direct


Create Availability Zone
##########################
    
    openstack aggregate create --zone atp-az atp-hag

Add a host to a Availability Zone
##################################
    
    openstack aggregate add host atp-hag ne-a2e-an-nfviplus-rk1-com1.tcloud

Create Flavor (CPU pinning siblings policy ++ Huge pages)
##########################################################
    
    openstack flavor create atp-cpu-siblings --ram 16384 --disk 50 --ephemeral 20 --vcpus 4
    openstack flavor set atp-cpu-siblings --property hw:cpu_policy=dedicated --property  hw:numa_nodes=1 --property hw:cpu_thread_policy=require --property hw:mem_page_size=1048576

    

Create Flavor (CPU pinning thread siblings + Huge pages)
##########################################################
    
    openstack flavor create atp-cpu-isolate --ram 16384 --disk 50 --ephemeral 20 --vcpus 4    
    openstack flavor set atp-cpu-isolate --property hw:cpu_policy=dedicated --property hw:numa_nodes=1 --property hw:cpu_thread_policy=isolate --property hw:mem_page_size=1048576
    
Upload Image
###############

    sudo yum install -y libguestfs-tools.noarch
    virt-customize -a CentOS-7-x86_64-GenericCloud.qcow2 --root-password password:redhat
    qemu-img convert -f qcow2 -O raw CentOS-7-x86_64-GenericCloud.qcow2 CentOS-7-x86_64-GenericCloud.raw
    openstack image create --container-format bare --disk-format raw --public --file CentOS-7-x86_64-GenericCloud.raw centos7


Create NS1 Network
####################
    
    openstack network create AN-NS1 --provider-network-type flat --provider-physical-network spgw_ns1 
    openstack subnet create AN-NS1-subnet --network AN-NS1 --no-dhcp --allocation-pool start=192.168.20.101,end=192.168.20.200 --gateway none --subnet-range=192.168.20.0/24
    openstack port create --network AN-NS1 --vnic-type direct sriov-1
    openstack port create --network AN-NS1 --vnic-type direct sriov-2
    neutron port-update 4eefe3dc-9138-4d43-b9fc-5fd1c73431c2 --allowed-address-pairs type=dict list=true ip_address=0.0.0.0/1 ip_address=128.0.0.0/1 ip_address=::/1 ip_address=8000::/1
    neutron port-update bd512332-7bd9-4622-aa16-029e90d6fc71 --allowed-address-pairs type=dict list=true ip_address=0.0.0.0/1 ip_address=128.0.0.0/1 ip_address=::/1 ip_address=8000::/1


Create instances
###################
    
    openstack server create --image centos7 --flavor atp-cpu-siblings  --availability-zone atp-az1 --nic port-id=6edc4f30-43d0-4787-abd0-4fcf93bfc3ff atp-sriov-vm1
    openstack server create --image centos7 --flavor atp-cpu-isolate --availability-zone atp-az1 --nic port-id=9ae5736e-983d-49c0-9ad6-f111cab19208 atp-sriov-vm2
    nova get-vnc-console atp-sriov-vm1 novnc
    nova get-vnc-console atp-sriov-vm2 novnc

    
Create volume
##############

    openstack volume create --size 60 atp-ceph-vol
    
Attach volume to a vm
#######################

    openstack server add volume atp-sriov-vm1 atp-ceph-vol 

    
Detach the volume from VM
###########################
    
    openstack server remove volume atp-sriov-vm1 atp-ceph-vol 
    openstack volume delete atp-ceph-vol
    
List Images from Ceph
########################    

    sudo rbd -p images ls
