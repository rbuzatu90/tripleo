#!/usr/bin/python
import os
import argparse
import json

parser = argparse.ArgumentParser()
parser.add_argument("-f", "--filename", help="data file, default: %s" % ('./ipmi_list'), action="store", metavar="FILE", default='./ipmi_list')
parser.add_argument("-d", "--delimiter", help="set the delimiter char, default is ' '", action="store", metavar='DELIM', default=' ')
parser.add_argument("-D", "--driver", help="set the driver type to use char, default is 'pxe_ipmitool'", action="store", metavar='TYPE', default='pxe_ipmitool')
parser.add_argument("-k", "--key", help="key file for pxe_ssh", action="store", metavar='TYPE', default='')

args = parser.parse_args()
filename = args.filename
delimiter = args.delimiter
driver = args.driver

if not os.path.isfile(filename):
    print "ipmi list file not found"
    exit(1)

try:
    with open(filename, 'r') as f:
        lines = f.readlines()
except IOError as e:
    print "Error opening file"

instackenv = {}
instackenv['nodes'] = []

controler_naming_pattern="controller,control,ctrl,cntrl"
compute_naming_pattern="cmpt,compute"
# Example of input file
# 14:9e:cf:45:b8:bb 10.171.54.207 root password1 controller1
# 14:9e:cf:45:b8:bb 10.171.54.217 root password1 cntrl3
# 14:9e:cf:45:b8:bb 10.171.54.1 root password1 cmpt1
# 14:9e:cf:45:b8:bb 10.171.54.2 root password1 compute2
try:
  for line in lines:
    elt = line.strip().split(delimiter)
    tmp = {}
    tmp['mac'] = []
    tmp['mac'].append(elt[0])
    tmp['name'] = elt[4]
    tmp['pm_user'] = elt[2]
    tmp['pm_password'] = elt[3]
    tmp['pm_addr'] = elt[1]
    if "cmpt" in elt[4] or "compute" in elt[4]:
      tmp['pm_type'] = driver
      tmp['capabilities'] = "profile:" + elt[4] + ",boot_option:local"
    elif "ctrl" in elt[4] or "control" in elt[4] or "cntrl" in elt[4] or "controller" in elt[4]:
      tmp['pm_type'] = driver
      tmp['capabilities'] = "profile:" + elt[4] + ",boot_option:local"
    if "contrail" in elt[4]:
      tmp['pm_type'] = 'pxe_ssh'
      if "analytics" in elt[4] and "database" not in elt[4]:
        tmp['capabilities'] = "profile:" + elt[4] + ",boot_option:local"
      if "control" in elt[4]:
        tmp['capabilities'] = "profile:" + elt[4] + ",boot_option:local"
      if "databese" in elt[4] or "db" in elt[4]:
        tmp['capabilities'] = "profile:" + elt[4] + ",boot_option:local"
        if "control" in elt[4]:
          tmp['capabilities'] = "profile:" + elt[4] + ",boot_option:local"
    instackenv['nodes'].append(tmp)
except IndexError as e:
    print "Error creating dict: %s" % (e)
    exit(1)

jsonarray = json.dumps(instackenv)

print jsonarray
with open('data.txt', 'w') as outfile:
    json.dump(instackenv,outfile,indent=2)
