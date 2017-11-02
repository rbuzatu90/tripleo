#!/bin/bash

ns=$1
cmd=$2
controller_ip=10.0.0.45

echo "Network is $ns"
ssh $controller_ip -t "sudo /sbin/ip netns exec qdhcp-$ns $cmd"
