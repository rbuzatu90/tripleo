#!/bin/bash

BASE_DIR=/root/tripleo
IMAGES_DIR=$BASE_DIR/../images/
UNDERCLOUD_RC_FILE=$BASE_DIR/stackrc
OVERCLOUD_RC_FILE=$BASE_DIR/overcloudrc.v3
TOPOLOGY_FILE=$BASE_DIR/topology.yaml
NETWORK_ISOLATION=$BASE_DIR/network-isolation.yaml
#NETWORK_ISOLATION=/usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml
NETWORK_ENVIRONMENT=$BASE_DIR/network-environment.yaml
STORAGE_ENVIRONMENT=$BASE_DIR/storage-environment.yaml
ENABLE_TLS=$BASE_DIR/tls/enable-tls.yaml
INJECT_TRUST_ANCHOR=$BASE_DIR/tls/inject-trust-anchor.yaml
TLS_ENDPOINTS=/usr/share/openstack-tripleo-heat-templates/environments/tls-endpoints-public-dns.yaml
ENV_RHEL_REG=$BASE_DIR/extraconfig/pre_deploy/rhel-registration/environment-rhel-registration.yaml
#RHEL_REG_RESOURCE_REG=/usr/share/openstack-tripleo-heat-templates/extraconfig/pre_deploy/rhel-registration/rhel-registration-resource-registry.yaml
RHEL_REG_RESOURCE_REG=$BASE_DIR/extraconfig/pre_deploy/rhel-registration/rhel-registration-resource-registry.yaml
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
time openstack overcloud node delete --stack 61bb6e01-4d7e-4bf1-aae8-9317f4a8a68b --templates \
    -e $TOPOLOGY_FILE \
    -e $NETWORK_ISOLATION \
    -e $INJECT_TRUST_ANCHOR \
    -e $ENABLE_TLS \
    -e $TLS_ENDPOINTS \
    -e $NETWORK_ENVIRONMENT \
    cf9151b9-6fea-4ea0-836f-189239b99e34


#    -e $ENV_RHEL_REG \
#    -e $RHEL_REG_RESOURCE_REG \
#    -e $STORAGE_ENVIRONMENT \
#    -e $ARTIFACTS \
#    -e $INJECT_TRUST_ANCHOR \
#    -e $ENABLE_TLS \
#    -e $TLS_ENDPOINTS \

