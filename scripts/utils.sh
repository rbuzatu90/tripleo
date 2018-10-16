for i in `ironic node-list | grep power | awk '{print $2}'`; do ironic node-delete $i;done
for i in `nova list | grep -v 'Status\|\+' | awk '{print $2}'`; do nova delete $i;done
for i in `nova list | grep ACTIVE | awk '{print $12}' | grep -o [0-9.]*`;do ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null heat-admin@$i ls;done
for i in `ironic node-list | grep None | awk '{print $2}'`; do ironic node-set-power-state $i on ; ironic node-set-maintenance $i off ;done

#crudini --set ~/undercloud.conf DEFAULT rpc_response_timeout 600

upload-swift-artifacts -f my_scripts.tgz --environment deploy_artifacts.yaml


git clone https://github.com/openstack/rally
./rally/install_rally.sh
rally verify create-verifier --type tempest --name my_tempest
rally deployment create --name my_overcloud --fromenv
rally verify start

rally verify start --pattern tempest.api.compute.admin
rally task start rally_boot.json
