hostname=idm
domain=mylab.test
realm=`echo $domain | awk '{print toupper($0)}'`
dm_password='mypasswd'
admin_password='mypasswd'
IP=192.168.122.22

echo "Setting UP IdM with hostname: $hostname"
echo "Setting UP IdM with domain: $domain"
echo "Setting UP IdM with realm: $realm"

yum update -y 
#reboot
yum install -y ipa-server.x86_64 ipa-server-dns.noarch ipa-server-trust-ad.x86_64 samba

hostnamectl set-hostname "$hostname.$domain"
echo "$IP $hostname.$domain $hostname" >> /etc/hosts
ipa-server-install --domain=$domain --realm=$realm --setup-adtrust --setup-dns --enable-compat --no-forwarders --no-reverse --ds-password `echo $dm_password` --admin-password `echo $admin_password`
