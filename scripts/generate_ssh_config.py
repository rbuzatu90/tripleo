#!/usr/local/bin/python
import sys

data = []
for line in sys.stdin.readlines():
  if 'ACTIVE' in line:
    data.append(line)

domain = 'nfvi.localdomain'
user = "heat-admin"
proxy = "nec-uc"
ssh_key = "/home/stack/.ssh/id_rsa"
subnet = ".".join(data[0].split("|")[6].split("=")[1].split('.')[:3])


def gen_director_ssh_config():
  for line in data:
    info = line.split("|")
    long_name = info[2].strip()
    fqdn = str(info[2] + "." + domain).replace(" ", "")
    short_name = info[2].split("-")[6].strip()
    ip_addr = info[6].split("=")[1]
    print "Host", fqdn, long_name, short_name, ip_addr 
    print "User", user
    print "StrictHostKeyChecking no"
    print "UserKnownHostsFile /dev/null"
    print "IdentityFile", ssh_key
    print "ProxyJump", proxy
    print "##############################################"

def gen_etc_hosts():
  for line in data:
    if 'ACTIVE' in line:
      x=line.split("|")
      print x[6].split("=")[1] + x[2] + x[2].split("-")[-1]

def gen_ssh_config():
  for line in data:
    if 'ACTIVE' in line:
      x=line.split("|")
      print "Host", x[6]

gen_director_ssh_config()
#gen_etc_hosts()
#gen_ssh_config()
