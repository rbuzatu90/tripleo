echo 'tmux session would be great'
hostname=satelli
domain=mylab.test
IP=192.168.122.89
organization=MyOrg
location=Dubai
user=admin
password=redhat
manifest=/root/manifest.zip
cv_name="test"
sat_iso=/root/satellite-6.2.15-rhel-7-x86_64-dvd.iso


mkdir -p /tmp/sat-mnt
echo "Mounting satellite ISO"
mount $sat_iso /tmp/sat-mnt
echo "Installing satellite dependencies"
cd /tmp/sat-mnt/
time ./install_packages

#https://access.redhat.com/articles/2258471

hostnamectl set-hostname "$hostname.$domain"
echo "$IP $hostname.$domain $hostname" >> /etc/hosts

echo "Installing satellite"
time satellite-installer --scenario satellite --foreman-initial-organization "$organization" --foreman-initial-location "$location" --foreman-admin-username $user --foreman-admin-password $password

mkdir .hammer
cat << EOF > .hammer/cli_config.yml
:foreman:
 :host: 'https://$hostname.$domain'
 :username: '$user'
 :password: "$password"
EOF

hammer subscription upload --file "$manifest" --organization "$organization"
hammer organization update --redhat-repository-url http://10.0.0.1 --name "$organization"

prod=$(hammer product list --organization-id 1 | egrep -i "Red.Hat.Enterprise.Linux.Server\s\s" | awk '{print $1}')
repo=$(hammer repository-set list --organization-id 1 --product-id $prod | egrep -i "\|.Red.Hat.Enterprise.Linux.7.Server\s.RPMs"  | awk '{print $1}')
hammer repository-set enable --id $repo --product-id $prod --organization-id 1 --releasever 7Server --basearch x86_64
