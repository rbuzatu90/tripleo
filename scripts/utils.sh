for i in `ironic node-list | grep power | awk '{print $2}'`; do ironic node-delete $i;done
for i in `nova list | grep -v 'Status\|\+' | awk '{print $2}'`; do nova delete $i;done
for i in `nova list | grep ACTIVE | awk '{print $12}' | grep -o "[0-9.]*"`;do ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null heat-admin@$i ls;done
for i in `nova list | grep ACTIVE | awk '{print $12}' | grep -o "[0-9.]*"`;do rsync --rsync-path="sudo rsync" ../.ssh/id_rsa $i:/root/.ssh/;done
for i in `ironic node-list | grep "None\|True" | awk '{print $2}'`; do ironic node-set-power-state $i on ; ironic node-set-maintenance $i off ;done
CEPH_NAME=stor; for i in `openstack baremetal node list -c Name -f value | grep $CEPH_NAME` ; do openstack baremetal node manage $i; openstack baremetal node clean $i --clean-steps '[{"interface": "deploy", "step": "erase_devices_metadata"}]';done # ironic ceph node clean 
for i in `openstack baremetal node list | grep manageable | awk '{print $2}'`; do openstack baremetal node provide $i;done # ironic baremetall manage to provide 
CTRL_NAME=ctrl; for i in `openstack baremetal node list -c Name -f value | grep -i $CTRL_NAME`; do openstack baremetal node show $i -c driver_info -f json | jq .driver_info; done # show driver / ipmi info
nova list | grep Running | awk '{print $4, $12}' | sed 's/ctlplane=//g' | awk -F '-' '{print $7}'
for i in `nova list | grep ERROR | awk '{print $2}'`; do nova reset-state $i --active; nova stop $i; nova start $i;done # recover from failed migration evacuation
openstack server list -c Name -c Networks  -f value | sed 's/ctlplane=//g' | while IFS=' ' read host ip ; do ./update-hosts.sh $ip $host ; done # update /etc/hosts overcloud

PASS=`grep "stats auth admin:" /var/lib/config-data/puppet-generated/haproxy/etc/haproxy/haproxy.cfg | awk -F\: '{print $2}'`
IPADDR=`grep ":1993" /var/lib/config-data/puppet-generated/haproxy/etc/haproxy/haproxy.cfg | grep -o "[0-9.]*" | head -1`
curl -s -u admin:$PASS "http://$IPADDR:1993/;csv" | egrep -vi "(frontend|backend)" | awk -F',' '{ print $1" "$2" "$18 }'

password=`crudini --get /var/lib/config-data/puppet-generated/nova_libvirt/etc/nova/nova.conf database connection | grep -o 'nova:[a-zA-Z0-9]*' | cut -d: -f2`
mysql -u nova -p -h $IPADDR -nNE -e "show variables like 'hostname';"

#crudini --set ~/undercloud.conf DEFAULT rpc_response_timeout 600

openstack baremetal node set --driver-info "ipmi_address=10.106.160.39" ctrl0 # Set IPMI address info
openstack baremetal node set --property capabilities='profile:compute,boot_option:local' cmpt0 # Set capabilities / profile

upload-swift-artifacts -f my_scripts.tgz --environment deploy_artifacts.yaml
rally verify start --pattern tempest.api.compute.admin
rally task start rally_boot.json


git clone https://github.com/openstack/rally
./rally/install_rally.sh
rally verify create-verifier --type tempest --name my_tempest
rally deployment create --name my_overcloud --fromenv
rally verify start

rally verify start --pattern tempest.api.compute.admin
rally task start rally_boot.json
