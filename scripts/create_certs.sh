openssl verify -verbose -CAfile CA_MyLab.pem srv_uc.mylab.test.crt
openssl req -text -noout -verify -in csr.csr
openssl x509 -text -noout -in certificate.pem

ORGANIZATION=MyLab
COUNTRY=RO
STATE=Ilfov
LOCATION=Bucharest
CA_DOMAIN=ca.mylab.test
OC_DOMAIN=oc.mylab.test
OC_ALT_DNS1=192.168.20.20
UC_DOMAIN=uc.mylab.test
UC_ALT_DNS1=192.168.20.10

openssl req -nodes -days 3650 -new -x509 -newkey rsa:4096 -keyout CA_${ORGANIZATION}.key -out CA_${ORGANIZATION}.pem -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${ORGANIZATION}/CN=${CA_DOMAIN}"
echo '00' > CA_${ORGANIZATION}.srl

# Undercloud
openssl genrsa -out ${UC_DOMAIN}.key 4096
openssl req -key ${UC_DOMAIN}.key -new -days 3640 -out ${UC_DOMAIN}.csr -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${ORGANIZATION}/CN=${UC_DOMAIN}"
openssl x509 -req -in ${UC_DOMAIN}.csr -days 3640 -CA CA_${ORGANIZATION}.pem -CAkey CA_${ORGANIZATION}.key -CAserial CA_${ORGANIZATION}.srl -out ${UC_DOMAIN}.crt -extensions v3_req -extfile <(
cat <<-EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $UC_DOMAIN 
DNS.2 = $UC_ALT_DNS1
IP.1 = $UC_ALT_DNS1
EOF
)

# Overcloud
openssl genrsa -out ${OC_DOMAIN}.key 4096
openssl req -key ${OC_DOMAIN}.key -new -days 3640 -out ${OC_DOMAIN}.csr -subj "/C=${COUNTRY}/ST=${STATE}/L=${LOCATION}/O=${ORGANIZATION}/CN=${OC_DOMAIN}"
openssl x509 -req -in ${OC_DOMAIN}.csr -days 3640 -CA CA_${ORGANIZATION}.pem -CAkey CA_${ORGANIZATION}.key -CAserial CA_${ORGANIZATION}.srl -out ${OC_DOMAIN}.crt -extensions v3_req -extfile <(
cat <<-EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $OC_DOMAIN
DNS.2 = $OC_ALT_DNS1
IP.1 = $OC_ALT_DNS1
EOF
)

