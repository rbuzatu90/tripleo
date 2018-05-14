#!/bin/bash

BASE_DIR=/root/tripleo
TEMPLATE_DIR=$BASE_DIR/templates
IMAGES_DIR=$BASE_DIR/../images/
UNDERCLOUD_RC_FILE=$BASE_DIR/stackrc

source $UNDERCLOUD_RC_FILE
for i in `ironic node-list | grep -i control | awk '{print $2}'`
    do ironic node-show $i | grep -i ipmi_address
done

pcs stonith create ipmi-controller-1 fence_ipmilan pcmk_host_list=controller-1 ipaddr=$IP_CONTOLLER_1 login=root passwd=calvin lanplus=1; pcs constraint location ipmi-controller-1 avoids controller-1
pcs stonith create ipmi-controller-2 fence_ipmilan pcmk_host_list=controller-2 ipaddr=$IP_CONTOLLER_2 login=root passwd=calvin lanplus=1; pcs constraint location ipmi-controller-2 avoids controller-2
pcs stonith create ipmi-controller-3 fence_ipmilan pcmk_host_list=controller-3 ipaddr=$IP_CONTOLLER_3 login=root passwd=calvin lanplus=1; pcs constraint location ipmi-controller-3 avoids controller-3

pcs property set stonith-enabled=true
