#!/usr/local/bin/python
import sys

data = sys.stdin.readlines()

domain = 'nfvi.localdomain'
user = "heat-admin"
proxy = "nec-uc"
ssh_key = "/home/stack/.ssh/id_rsa"
subnet = ".".join(data[4].split("|")[6].split("=")[1].split('.')[:3])

print "Host" , subnet + ".*"
print "User", user
print "StrictHostKeyChecking no"
print "UserKnownHostsFile /dev/null"
print "IdentityFile", ssh_key
print "ProxyJump", proxy

for line in data:
    if 'ACTIVE' in line:
      x=line.split("|")
      print x[6].split("=")[1] + x[2] + x[2].split("-")[-1]

