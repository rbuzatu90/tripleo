#!/bin/bash
ceph_health=`ceph -s -f json | jq .health.status`
total_OSD=`ceph -s -f json | jq .osdmap.osdmap.num_osds`
in_OSD=`ceph -s -f json | jq .osdmap.osdmap.num_in_osds`
echo "Total OSDs is $total_OSD"
echo "OSDs in cluster is $in_OSD"
target_osd_up=80
osd_min=$(( $total_OSD*$target_osd_up/100 ))
if [ $ceph_health ~= HEALTH_OK ]; then
	echo "Health OK"
	exit 0
elif [ $ceph_health ~= HEALTH_ERROR ]; then
	echo "Health ERROR"
	exit 1
elif [[ $in_OSD -lt $osd_min ]] ; then
        echo "Not enough OSDs in, Retring"
        exit 1
fi
