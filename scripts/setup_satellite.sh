echo 'tmux session would be great'
hostname=satellite
domain=mylab.test
IP=192.168.122.89
organization=MyOrg
location=Dubai
user=admin
password=redhat
manifest=/root/manifest.zip
cv_name="MyCV"
activ_key="MyKey"
repo_url=192.168.122.1/iso/
sat_iso=/root/satellite-6.2.15-rhel-7-x86_64-dvd.iso
rhel_release=7.4

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

# Product "Red Hat Enterprise Linux Server"
prod=$(hammer product list --organization-id 1 | egrep -i "Red.Hat.Enterprise.Linux.Server\s\s" | awk '{print $1}')

repo=$(hammer repository-set list --organization-id 1 --product-id $prod | grep -i '| Red Hat Enterprise Linux 7 Server (RPMs)' | awk '{print $1}')
hammer repository-set enable --id $repo --product-id $prod --organization-id 1 --releasever $rhel_release --basearch x86_64

repo=$(hammer repository-set list --organization-id 1 --product-id $prod | grep -i 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)' | awk '{print $1}')
hammer repository-set enable --id $repo --product-id $prod --organization-id 1 --releasever $rhel_release --basearch x86_64

repo=$(hammer repository-set list --organization-id 1 --product 'Red Hat Enterprise Linux Server' | grep -i 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)' | awk '{print $1}')
hammer repository-set enable --id $repo --product-id $prod --organization-id 1 --releasever $rhel_release--basearch x86_64   # --releasever may not be valid

repo=$(hammer repository-set list --organization-id 1 --product 'Red Hat Enterprise Linux Server' | grep -i 'Red Hat Enterprise Linux 7 Server - RH Common (RPMs)' | awk '{print $1}')
hammer repository-set enable --id $repo --product-id $prod --organization-id 1 --releasever $rhel_release --basearch x86_64

repo=$(hammer repository-set list --organization-id 1 --product 'Red Hat Enterprise Linux Server' | egrep -i 'satellite tools\s6.2\s.*7 Server\)\s.R' | awk '{print $1}')
hammer repository-set enable --id $repo --product-id $prod --organization-id 1 --releasever $rhel_release --basearch x86_64

# Product "Red Hat Openstack Platform"
prod=$(hammer product list --organization-id 1 | egrep -i "openstack" | grep -v Beta | awk '{print $1}')
repo=$(hammer repository-set list --organization-id 1 --product-id $prod | grep 'Red Hat OpenStack Platform 10 for RHEL 7 (RPMs)' | awk '{print $1}')
hammer repository-set enable --id $repo --product-id $prod --organization-id 1 --releasever $rhel_release --basearch x86_64

# Product "Red Hat Openstack Platform"
# TBD

#Check enabled repos
# TBD

repos=$(hammer --csv repository list --organization-id 1 | egrep -vi 'id' |awk -F, '{print $1}')
for i in $repos; do hammer repository synchronize --async --id $i --organization-id 1;done

# Check synced repos
# RBD
#
#hammer task progress --id 640bb71f-0ce5-40a3-a675-425a4acacceb
#hammer repository list --organization $ORG
#
#
hammer content-view create --name $cv_name --repository-ids `echo $repos | tr "\ " ","` --description "My Content View" --organization-id 1
cv=$(hammer content-view list --organization-id 1 | grep -i "$cv_name" | awk '{print $1}')
hammer content-view publish --id $cv --organization-id 1 --async

# Check CV
hammer content-view info --id $cv

hammer activation-key create --name "$activ_key" --organization-id 1 --content-view-id $cv --lifecycle-environment Library
prod=$(hammer product list --organization-id 1 | egrep -i "Red.Hat.Enterprise.Linux.Server\s\s" | awk '{print $1}')
repo=$(hammer repository-set list --organization-id 1 --product-id $prod | egrep -i "\|.Red.Hat.Enterprise.Linux.7.Server\s.RPMs"  | awk '{print $1}')
hammer repository-set enable --id $repo --product-id $prod --organization-id 1 --releasever 7Server --basearch x86_64
