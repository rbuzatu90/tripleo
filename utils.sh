#crudini --set ~/undercloud.conf DEFAULT rpc_response_timeout 600

upload-swift-artifacts -f my_scripts.tgz --environment deploy_artifacts.yaml

source /root/stackrc

nova list --fields name,networks | grep ctlplane | awk '{print $6, $4}' | sed  's/ctlplane=//g' >> /etc/hosts 
function set_debug() {
    # Debug for controllers
    for i in `nova list | grep controller| awk '{print $12}'| egrep -o  "[0-9.]*"`; do
        echo $i
        ssh $i 'sudo crudini --set /etc/nova/nova.conf DEFAULT debug true; sudo crudini --set /etc/glance/glance-api.conf DEFAULT debug true ;sudo crudini --set /etc/cinder/cinder.conf DEFAULT debug true ;sudo crudini --set /etc/neutron/neutron.conf DEFAULT debug true; sudo crudini --set /etc/glance/glance-registry.conf DEFAULT debug true; for i in `systemctl list-units | grep openstack | grep -v gnocchi | grep -v ceilometer | grep -v aodh | cut -d . -f 1`; do sudo systemctl restart $i ;done' &
    done

    # Debug for compute 
    for i in `nova list | grep compute| awk '{print $12}'| egrep -o  "[0-9.]*"`; do
        ssh $i 'sudo crudini --set /etc/nova/nova.conf DEFAULT debug true ;sudo crudini --set /etc/neutron/neutron.conf DEFAULT debug true; log_dir=/var/log; sudo rm -rf /var/log/nova/nova-comp*  ; sudo rm -rf $log_dir/neutron/*; for i in `systemctl list-units | grep "nova\|neutron" | cut -d . -f 1`; do sudo systemctl restart $i ;done' &
    done
}

set_debug
