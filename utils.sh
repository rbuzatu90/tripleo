#crudini --set ~/undercloud.conf DEFAULT rpc_response_timeout 600

upload-swift-artifacts -f my_scripts.tgz --environment deploy_artifacts.yaml


git clone https://github.com/openstack/rally
./rally/install_rally.sh
rally verify create-verifier --type tempest --name my_tempest
rally deployment create --name my_overcloud --fromenv
rally verify start

