hostname=idm
domain=mylab.test
realm=`echo $domain | awk '{print toupper($0)}'`
dm_password='mypasswd' # Must be 8 or longer
admin_password='mypasswd' # Must be 8 or longer
IP=192.168.122.22

echo "Setting UP IdM with hostname: $hostname"
echo "Setting UP IdM with domain: $domain"
echo "Setting UP IdM with realm: $realm"

yum update -y 
#reboot
yum install -y ipa-server.x86_64 ipa-server-dns.noarch ipa-server-trust-ad.x86_64 samba firewalld

hostnamectl set-hostname "$hostname.$domain"
echo "$IP $hostname.$domain $hostname" >> /etc/hosts
# Install server
ipa-server-install --domain=$domain --realm=$realm --setup-adtrust --setup-dns --enable-compat --no-forwarders --ds-password `echo $dm_password` --admin-password `echo $admin_password` --ca-subject="CN=$hostname.$domain,O=$realm" --subject-base="O=$realm"

# Install replica
ipa-replica-install --principal admin --admin-password $admin_password --force-join

systemctl enable firewalld
systemctl start firewalld
firewall-cmd \
   --permanent \
   --add-service=freeipa-ldaps \
   --add-service=freeipa-ldap \
   --add-service=freeipa-replication \
   --add-service=freeipa-trust \
   --add-service=https \
   --add-service=http \
   --add-service=dns \
   --add-service=ntp
firewall-cmd --reload

# Generate cert for OpenStack API endpoint
# Using openssl commands generate key and CSR for openstack endpoint
# Create a host principal for the requiered CN / SAN. All should have separate principals
ipa host-add overcloud.mylab.test --force
# Based on the previously created CSR generate the certificate
ipa cert-request srv_overcloud.mylab.test.csr --principal=host/overcloud.mylab.test --profile-id=caIPAserviceCert --certificate-out=srv_overcloud.mylab.test.crt

ipa group-add --desc="OpenStack Users" grp-openstack
ipa user-add svc-ldap --first=SVC --last=LDAP  --email=svc-ldap@mylab.test --homedir=/home/work/svc-ldap --password
ipa group-add-member --users=svc-ldap grp-openstack
