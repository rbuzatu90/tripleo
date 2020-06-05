openstack project create openshift
openstack role add --user admin --project openshift admin
openstack quota set --cores -1 --gigabytes -1 --floating-ips -1 --ram -1 openshift

openstack role add --user admin --project admin swiftoperator
openstack object store account set --property Temp-URL-Key=superkey

IMAGES='/home/stack/images'
openstack image create --public --container-format=bare --disk-format=qcow2 --file $IMAGES/rhel-server-7.8-cloud.qcow2 rhel7


for i in `openstack security group list -c ID -f csv | grep -v ID | tr -d '"'`; do
    openstack security group rule create --protocol icmp $i
    openstack security group rule create  --dst-port 1:65000 $i
done

openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey

openstack flavor create m1.small --id auto --ram 1024 --disk 50 --vcpus 2

neutron net-create private-net --provider:network_type vxlan
subnet="10.0.0"
neutron subnet-create private-net --dns-nameserver 172.21.0.1 --enable-dhcp --allocation-pool start=$subnet.60,end=$subnet.100 --gateway $subnet.1 $subnet.0/24 --name private-subnet

neutron net-create --router:external --provider:network_type vlan --provider:segmentation_id 206 --provider:physical_network datacentre public-net
subnet="172.21.0"
neutron subnet-create public-net --dns-nameserver 172.21.0.1 --enable-dhcp --allocation-pool start=$subnet.160,end=$subnet.200 --gateway $subnet.1 $subnet.0/24 --name public-subnet
#neutron subnet-update --dns-nameserver 172.24.16.111 --dns-nameserver 172.24.16.112 `openstack subnet list | grep ocp | grep node | awk '{print $2}'`

fip1=`openstack floating ip create --floating-ip-address 172.21.0.167 public-net -c floating_ip_address -f value` # FIP for ocp admin VM
openstack floating ip create --floating-ip-address 172.21.0.166 public-net # api
openstack floating ip create --floating-ip-address 172.21.0.177 public-net # *.apps

neutron router-create external-router
neutron router-interface-add external-router private-subnet
neutron router-gateway-set external-router public-net


secgrp=`openstack security group list --project admin -c ID -f value`
netid=`openstack network list --internal  | grep private | awk '{print $2}'`
vmid1=`openstack server create --image rhel7 --flavor m1.small --security-group $secgrp --key-name mykey --nic net-id=$netid ocp -c id -f value`
sleep 100
openstack server add floating ip $vmid1 $fip1

openstack flavor create --ram 7192 --disk 50 --vcpu 8 --private --project openshift  --insecure  ocp.master.big
openstack flavor create --ram 7192 --disk 50 --vcpu 8 --private --project openshift  --insecure  ocp.infra.big
openstack flavor create --ram 4096 --disk 50 --vcpu 4 --private --project openshift  --insecure  ocp.infra.small
openstack flavor create --ram 6192 --disk 50 --vcpu 4 --private --project openshift  --insecure  ocp.worker.medium

# set ssh key and project details in clouds.yaml
rsync clouds.yaml install-config.yaml cloud-user@172.21.0.167:

# On OCP admin
ssh cloud-user@172.21.0.167
# enable-repos
# install-rpms
sudo wget -c 'https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-install-linux.tar.gz'
#sudo wget -c 'https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz'
tar -xvzf openshift-client-linux.tar.gz
tar -xvzf openshift-install-linux.tar.gz
mkdir ~/ocp
cp clouds.yaml install-config.yaml ~/ocp
sudo mv oc kubectl openshift-install /usr/sbin/
rm -f openshift*
sudo reboot

time openshift-install create cluster --dir=/home/cloud-user/ocp/ --log-level=debug
export KUBECONFIG=/home/cloud-user/ocp/auth/kubeconfig






openstack router add subnet external-router `openstack subnet list | grep ocp | grep nodes | awk '{print $2}'`
openstack router show `openstack router list | grep ocp | grep external-router | awk '{print $2}'` -c external_gateway_info -f value | jq .external_fixed_ips[0].ip_address
openstack router show external-router -c external_gateway_info -f value | jq .external_fixed_ips[0].ip_address
openstack floating ip set --port `openstack port list | grep ingress-port | awk '{print $2}'` 172.21.0.177
ssh core@`openstack server list --all | grep bootstrap | grep -o "172.21.0.[0-9]*"` 'journalctl -b -f -u bootkube.service'
