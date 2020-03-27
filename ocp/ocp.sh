openstack role add --user admin --project admin swiftoperator
openstack object store account set --property Temp-URL-Key=superkey
openstack project create openshift
openstack role add --user admin --project openshift admin
openstack quota set --cores -1 --gigabytes -1 --floating-ips -1 --ram -1 openshift

fip1=`openstack floating ip create --floating-ip-address 192.168.122.167 public-net -c floating_ip_address -f value`
secgrp=`openstack security group list --project admin -c ID -f value`
netid=`openstack network list --internal  | grep private | awk '{print $2}'`
vmid1=`openstack server create --image rhel7.7 --flavor m1.small --security-group $secgrp --key-name mykey --nic net-id=$netid ocp -c id -f value`
openstack server add floating ip $vmid1 $fip1

#neutron subnet-update --dns-nameserver 172.24.16.111 --dns-nameserver 172.24.16.112 `openstack subnet list | grep ocp | grep node | awk '{print $2}'`
openstack image create --container-format=bare --disk-format=qcow2 --file rhcos-4.3.0-x86_64-openstack.qcow2 rhcos 

openstack floating ip create --floating-ip-address 192.168.122.166 public-net # api
openstack floating ip create --floating-ip-address 192.168.122.177 public-net # *.apps

openstack flavor create --ram 8192 --disk 50 --vcpu 8 --private --project openshift  --insecure  ocp.master.big
openstack flavor create --ram 8192 --disk 50 --vcpu 8 --private --project openshift  --insecure  ocp.infra.big
openstack flavor create --ram 4096 --disk 50 --vcpu 4 --private --project openshift  --insecure  ocp.infra.small
openstack flavor create --ram 8192 --disk 50 --vcpu 2 --private --project openshift  --insecure  ocp.worker.medium


# On OCP admin

ssh cloud-user@192.168.122.167
sudo subscription-manager register --username=rbuzatu@redhat.com
pool=$(sudo subscription-manager list --available | grep -v "^ " | grep -m1 -A 5 "Employee SKU" | grep Pool | awk '{print $3}')
sudo subscription-manager attach --pool=$pool
sudo subscription-manager repos --disable=*
sudo subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-extras-rpms --enable=rhel-7-server-rh-common-rpms --enable=rhel-7-server-satellite-tools-6.4-rpms --enable=rhel-7-server-optional-rpms
sudo yum install -y vim telnet wget tcpdump nmap tmux git crudini jq net-tools yum-utils
sudo yum update -y
sudo wget -c 'https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux-4.3.8.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-4.3.8.tar.gz'
sudo reboot
# get clouds.yaml and install-config.yaml

tar -xvzf openshift-client-linux-4.3.8.tar.gz
tar -xvzf openshift-install-linux-4.3.8.tar.gz
sudo mv oc kubectl openshift-install /usr/sbin/
rm -f openshift-client-linux-4.3.8.tar.gz openshift-install-linux-4.3.8.tar.gz

time openshift-install create cluster --dir=/home/cloud-user/ocp/ --log-level=debug
