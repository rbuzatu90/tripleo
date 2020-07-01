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

# Example of input file
# 3C:FD:FE:D3:DF:E0 10.237.53.68 rk1-com1 compute-zone1-0
# 3C:FD:FE:E9:41:90 10.237.53.69 rk1-com2 compute-zone1-1
try:
  for line in lines:
    elt = line.strip().split(delimiter)
    tmp = {}
    tmp['pm_user'] = 'root'
    tmp['pm_type'] = 'ipmi'
    tmp['pm_password'] = 'calvin'
    tmp['mac'] = []
    tmp['mac'].append(elt[0])
    tmp['name'] = elt[2]
    tmp['pm_addr'] = elt[1]
    tmp['capabilities'] = "boot_option:local," + "node:" + elt[3]
    instackenv['nodes'].append(tmp)
except IndexError as e:
    print "Error creating dict: %s" % (e)
    exit(1)

print(json.dumps(instackenv,indent=2))
