#!/bin/bash

BASE_DIR=/root/tripleo
IMAGES_DIR=$BASE_DIR/../images/
UNDERCLOUD_RC_FILE=$BASE_DIR/stackrc
OVERCLOUD_RC_FILE=$BASE_DIR/overcloudrc.v3
TOPOLOGY_FILE=$BASE_DIR/topology.yaml
NETWORK_ISOLATION=/usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml
NETWORK_ENVIRONMENT=$BASE_DIR/network-environment.yaml
STORAGE_ENVIRONMENT=$BASE_DIR/storage-environment.yaml
ENABLE_TLS=$BASE_DIR/enable-tls.yaml
INJECT_TRUST_ANCHOR=$BASE_DIR/inject-trust-anchor.yaml
TLS_ENDPOINTS=/usr/share/openstack-tripleo-heat-templates/environments/tls-endpoints-public-dns.yaml
FIXED_IPS=$BASE_DIR/fixed-ips.yaml
ARTIFACTS=$BASE_DIR/deploy_artifacts.yaml

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

source $UNDERCLOUD_RC_FILE
# Deploy
time openstack overcloud deploy --templates \
    -r roles_data_simple.yaml \
    -e $TOPOLOGY_FILE \
    -e $NETWORK_ISOLATION \
    -e $STORAGE_ENVIRONMENT \
    -e $INJECT_TRUST_ANCHOR \
    -e $ENABLE_TLS \
    -e $TLS_ENDPOINTS \
    -e cloudname.yaml \
    -e $NETWORK_ENVIRONMENT \
    -e timezone.yaml \
    --verbose \
    --ntp-server pool.ntp.org


#    -e $ARTIFACTS \
#    -e $INJECT_TRUST_ANCHOR \
#    -e $ENABLE_TLS \
#    -e $TLS_ENDPOINTS \
#    -e $FIXED_IPS \

export DEPLOYMENT_RESULT=$?
yes | cp /etc/hosts.base /etc/hosts; source $UNDERCLOUD_RC_FILE; nova list --fields name,networks | grep ctlplane | awk '{print $6, $4}' | sed  's/ctlplane=//g' >> /etc/hosts
echo 'export PYTHONWARNINGS="ignore:Certificate has no, ignore:A true SSLContext object is not available, ignore:Certificate for"' >> overcloudrc.v3
echo "Deployment exited with $DEPLOYMENT_RESULT"
if [[ $DEPLOYMENT_RESULT -ne 0 ]]; then
    echo "Deployment failed, exiting"
    exit 1
fi
#./init_openstack.sh
