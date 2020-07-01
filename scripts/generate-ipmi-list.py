#!/usr/bin/python
import re 

# Get all nodes NIC MACs
#for i in {68..86}; do echo 10.237.53.$i >> nodes.txt ; sshpass -p 'calvin' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@10.237.53.$i 'hwinventory nic' >> nodes.txt ;done
filename = 'nodes.txt'
try:
    with open(filename, 'r') as f:
        lines = f.readlines()
except IOError as e:
    print "Error opening file"

data = []
for line in lines:
    ip = re.search(r'[0-9.]*', line)
    interface = re.search('^NIC.Slot.1-1-1', line) # NIC.Slot.1-1-1 is the interface to PXE boot
    ip = ip.group() # IP of server should be present 1st
    if ip:
	data.append(ip)
    try:
	if interface.group():
    	    mac = re.search(r'([a-fA-F0-9]{2}[:|\-]?){6}', line)
            data.append(mac.group())
    except:
	pass


for i in range(0, len(data)-1, 2):
    x = data[i+1], data[i], 'rk1-com1 compute-zone1-0'
    print(' '.join(x))

# 3C:FD:FE:D3:DF:E0 10.237.53.68 rk1-com1 compute-zone1-0
# 3C:FD:FE:E9:41:90 10.237.53.69 rk1-com2 compute-zone1-1
