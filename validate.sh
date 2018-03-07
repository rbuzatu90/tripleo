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

source $OVERCLOUD_RC_FILE

time openstack orchestration template validate --show-nested --template ~/overcloud-validation/overcloud.yaml \
    -e ~/overcloud-validation/overcloud-resource-registry-puppet.yaml \
    -e $TOPOLOGY_FILE \
    -e $NETWORK_ISOLATION \
    -e $INJECT_TRUST_ANCHOR \
    -e $ENABLE_TLS \
    -e $TLS_ENDPOINTS \
    -e $NETWORK_ENVIRONMENT \
    --verbose
