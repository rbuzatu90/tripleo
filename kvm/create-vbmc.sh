

sudo yum install -y python-virtualbmc --enablerepo=centos-openstack-queens
pass='changeme'
vbmc add ctrl0 --port 11110 --username admin --password $pass 
vbmc add ctrl1 --port 11111 --username admin --password $pass 
vbmc add ctrl2 --port 11112 --username admin --password $pass 
vbmc add cmpt0 --port 11113 --username admin --password $pass 
vbmc add cmpt1 --port 11114 --username admin --password $pass 
vbmc add cmpt2 --port 11115 --username admin --password $pass 


vbmc start cmpt0
vbmc start cmpt1
vbmc start cmpt2
vbmc start ctrl0
vbmc start ctrl1
vbmc start ctrl2
