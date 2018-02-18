for i in `ironic node-list | grep power | awk '{print $2}'`; do ironic node-delete $i;done
#crudini --set ~/undercloud.conf DEFAULT rpc_response_timeout 600

upload-swift-artifacts -f my_scripts.tgz --environment deploy_artifacts.yaml


git clone https://github.com/openstack/rally
./rally/install_rally.sh
rally verify create-verifier --type tempest --name my_tempest
rally deployment create --name my_overcloud --fromenv
rally verify start

rally verify start --pattern tempest.api.compute.admin
rally task start rally_boot.json
