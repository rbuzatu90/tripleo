#!/bin/bash

set +x

BASE_DIR=/root/tripleo
IMAGES_DIR=$BASE_DIR/../images/
UNDERCLOUD_RC_FILE=$BASE_DIR/stackrc
OVERCLOUD_RC_FILE=$BASE_DIR/overcloudrc.v3
TOPOLOGY_FILE=$BASE_DIR/1compute3controller.yaml
NETWORK_ISOLATION=/usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml
NETWORK_ENVIRONMENT=$BASE_DIR/network-environment.yaml
STORAGE_ENVIRONMENT=$BASE_DIR/storage-environment.yaml
ENABLE_TLS=$BASE_DIR/enable-tls.yaml
INJECT_TRUST_ANCHOR=$BASE_DIR/inject-trust-anchor.yaml
FIXED_IPS=$BASE_DIR/fixed-ips.yaml

source $UNDERCLOUD_RC_FILE
yum install rhosp-director-images rhosp-director-images-ipa
cd $IMAGES_DIR
for i in /usr/share/rhosp-director-images/overcloud-full-latest-10.0.tar /usr/share/rhosp-director-images/ironic-python-agent-latest-10.0.tar; do tar -xvf $i; done
# Customize overcloud img
openstack overcloud image upload --image-path $IMAGES_DIR
openstack subnet set --dns-nameserver 8.8.8.8 <SUBNET_ID>


openstack baremetal import --json nodes.json

time openstack overcloud node introspect --all-manageable --provide
#time openstack  baremetal introspection bulk start
#openstack baremetal node manage [NODE UUID]
#openstack overcloud node introspect [NODE UUID] --provide

openstack overcloud profiles list

openstack baremetal introspection data save <ironic-node> | jq ".inventory.disks"


openstack baremetal node set --property root_device='{"serial": "61866da04f380d001ea4e13c12e36ad6"}' <ironic-node>
