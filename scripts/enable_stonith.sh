#!/bin/bash

BASE_DIR=/root/tripleo
TEMPLATE_DIR=$BASE_DIR/templates
IMAGES_DIR=$BASE_DIR/../images/
UNDERCLOUD_RC_FILE=$BASE_DIR/stackrc

source $UNDERCLOUD_RC_FILE
user=root
passwd=Changeme_123
for i in `openstack baremetal node list -c Name -f value | grep -i control`; do
  ip=`openstack baremetal node show $i -c driver_info -f json | jq .driver_info.ipmi_address | tr -d '"'`;echo "$i - $ip"
  echo pcs stonith create ipmi-$i fence_ipmilan pcmk_host_list=$i ipaddr=$ip login=$user passwd=$passwd lanplus=1; echo pcs constraint location ipmi-$i avoids $i
  echo '##############'
done

pcs property set stonith-enabled=true
