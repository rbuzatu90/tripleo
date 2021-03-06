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
ipa-server-install --domain=$domain --realm=$realm --ds-password `echo $dm_password` --admin-password `echo $admin_password` --ca-subject="CN=$hostname.$domain,O=$realm" --subject-base="O=$realm" --setup-dns --forwarder=8.8.8.8 --auto-reverse --setup-adtrust --enable-compat
ipa dnszone-add $domain # create forward zone
ipa dnszone-add --name-from-ip=192.168.122.0/24 # create reverse zone
ipa dnsrecord-add $domain idm1 --a-rec=192.168.122.8 --a-create-reverse
ipa dnsrecord-add $domain idm2 --a-rec=192.168.122.9 --a-create-reverse
ipa dnsrecord-add 122.168.192.in-addr.arpa. 8 --ptr-rec=idm1.$domain.
ipa dnsrecord-add 122.168.192.in-addr.arpa. 9 --ptr-rec=idm2.$domain.

# Install replica
ipa-client-install --principal admin -w $admin_password --force-join --mkhomedir -U
ipa-replica-install --principal admin --admin-password $admin_password --force-join # or -P admin -w 'admin_password'
ipa-ca-install; ipa-dns-install

systemctl enable firewalld
systemctl start firewalld
firewall-cmd \
   --permanent \
   --add-service=freeipa-ldaps \
   --add-service=freeipa-ldap \
   --add-service=freeipa-replication \
   --add-service=freeipa-trust \
   --add-service=kerberos \
   --add-service=https \
   --add-service=http \
   --add-service=dns \
   --add-service=ntp
firewall-cmd --reloada

ipa sudorule-add --cmdcat=all --hostcat=all all-sudo
ipa sudorule-add-user --groups=admins all-sudo

ipa user-add rbuz --first=Remus --last=Buzatu --password
ipa user-mod rbuz --user-auth-type=otp --user-auth-type=password
ipa otptoken-add --owner=rbuz rbuz-otp --digits=6 --counter=1 --type=hotp

# Generate cert for OpenStack API endpoint
# Using openssl commands generate key and CSR for openstack endpoint
# Create a host principal for the requiered CN / SAN. All should have separate principals
ipa host-add overcloud.mylab.test --force
# Based on the previously created CSR generate the certificate
ipa cert-request srv_overcloud.mylab.test.csr --principal=host/overcloud.mylab.test --profile-id=caIPAserviceCert --certificate-out=srv_overcloud.mylab.test.crt

ipa host-add client1.mylab.test
ipa service-add http/client1.mylab.test
ipa service-add-host --host client1.mylab.test http/client1.mylab.test

ipa group-add --desc="OpenStack Users" grp-openstack
ipa user-add svc-ldap --first=SVC --last=LDAP  --email=svc-ldap@mylab.test --homedir=/home/work/svc-ldap --password
ipa group-add-member --users=svc-ldap grp-openstack

# Check DNS records are in place
NAMESERVER=172.17.11.137
DOMAIN=mylab.test
for i in _ldap._tcp _kerberos._tcp _kerberos._udp _kerberos-master._tcp _kerberos-master._udp _ntp._udp ; do dig @${NAMESERVER} ${i}.${DOMAIN} srv +nocmd +noquestion +nocomments +nostats +noaa +noadditional +noauthority; done | egrep "^_"

ldapsearch -x -h `hostname` -D "cn=Directory Manager" -w $dm_password -b "dc=mylab,dc=test" -s sub on
ldapsearch -D "cn=directory manager" -w $dm_password -p 389  -b "uid=dummyuser,cn=users,cn=accounts,dc=nfvi,dc=localdomain" -h $IP

# Check client has open ports for IdM integration
ports="80 443 88 389 636 464"
hosts="10.237.191.78 10.237.191.79 10.237.221.78 10.237.221.79"
for port in $ports; do
    for host in $hosts; do
        echo "========= $host  $port ========= "
        timeout 1 nc -v $host $port
    done
done

openssl x509 -req -in ipa.csr -days 3640 -CA CA_MyLab.pem -CAkey CA_MyLab.key -CAserial CA_Serial.srl -out srv.crt -extensions v3_req -extfile <(
cat <<-EOF
[req]
keyUsage = critical,digitalSignature,keyEncipherment
default_md = sha256
distinguished_name = dn
req_extensions  = v3_req
subjectKeyIdentifier = hash
x509_extensions = usr_cert

[ usr_cert ]
basicConstraints = critical,CA:true
nsCertType = client, server, email
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer

[ v3_req ]
basicConstraints = critical,CA:true
nsCertType = sslCA, emailCA
keyUsage = nonRepudiation, cRLSign, digitalSignature, keyCertSign
subjectKeyIdentifier = hash
EOF

