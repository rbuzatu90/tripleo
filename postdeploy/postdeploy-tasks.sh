#!/bin/bash
# A heat-config-script which runs post-deploy actions for Cinder and Glance NetApp configuration.
# Inputs:
#   UNDERCLOUD_IP - IP of the Undercloud
#   glance_nfs_export - Name of the Copy Offload binary

echo "Post deploy" > /root/deployment_finished
sudo timedatectl set-timezone Europe/Bucharest
sudo cat <<EOF >> /root/.ssh/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAvd8fRvXxArOS3L0undhmlqocOMdP8Cbi3kctsIecx8LunyUE
O14NYE6s6uBG/3XTPKgrcbvcFNq8+VbGmZR+EB+p7OZ7HsTAl1+RxOeerjlxoKbl
SRqr9llt8zpsnxQctRQ8Q1jk+lFWX8uhvmrd2cU212CLgEb7OYo3t5llMX8oj2TH
XG/CUL7zLmgg9IrOrfuO6VzmYybHzMvQfVfdjMKq2gfHuy5i08s38cUj8ge8WGW+
MmHBUYrs6/z4IpPFBTRzCMtJ6hj0EbNsOWeY25dBnwgdGki7gaeuvMg5nd+7C35i
CdjCm3mfAbR7ID/mwKCx9IdPPxAbMwYJydhVhwIDAQABAoIBAQCL2V7BNn8pHTkL
6y/9xRly2aLl0zA2032AeO7XOluo6xQ1Fd+zFohFqk1ExqKkoJVQ9RDiuZrVpXNR
N7AaCLx9hcT0H6MJu6ObGyJT5MIE03y09pilKscEMUSBxUOiO/8VBO2KMVyeXvB+
qI7eoPn833yQUKUPe7io3fxB9/MH67sYYAFipMPYQf+fo41UoKAaztpldJKUfB4Z
0VgZBnsj+MwISxik1Ege67NujCOh3neVB/laNJfshLsvmxavH0CP5DxjijgQSEdH
TnYTKvpupg/xpb/Pm+CCOBn8WO6EcHRaOXH/L+nhYNBqDuEzBnG9q26Tee8oFfBx
KzEs0qzpAoGBAN8TpA6ZzBaEHyC9xnXiCAjf8r0pzZQ5VGdL1d6TVtZ9/6bfRHmk
8O7mdmH3/ix7sW/iBPq2lXeikwmpSG3vyFnN1QntXQb1gF8R9yA26aL8jl9/loG+
hMZ+6cmVpp8Xgp8cYYwtFV4j50MNDlmoAdTbbD033NpgQ3XWV7JMbIUNAoGBANnk
6cmCocUXUBNYRE1doNglnsQuOdMll15K5qEVSCvzccBsqcT/+hAbBr8w5ctX4m7f
nDfH3AnIRcpzE3VZg9cyqLfGBufmHFNuFwJn60q+TgqrNgKeb6CR0Zicp6Rp6UH0
q/I8yXQwqWSXGy422SXJqdm+8DQQEUDMbkOtJwfjAoGAahxnn2JdCCDUxbg/3Pcl
p0MPrhdiaK1UjsYt92/SkLjikLgHVG23BYyupy9VwkccQgIbKD8NnhjBJIlXoKO8
g6s7OTulUpgY9iAPk01LmXHVL2v7ZcAAXIMmJfN/jJGcWp8fb5RKY7tkWCqvtsoK
BPxS4lPeRCoiLL1GfdOIk0kCgYAekwxrBjWE3lySGlSbNoQXUFAS3xmmEyRGSuRJ
vh6+bA6OHbFEv1ZrZB9yPH5CJjbTr/TPru+lP8DrQ3J7iPADBky+XL8jUxquakg4
QjS17DYvMQ8HFww6z7tFWtX7MBFW++oUt4rdDub2Am4B8hhOQRngP/acl5SULxtZ
y7YqWQKBgAEJwO//wxmmtX6ieH3MMwOiZHCI6eLjO6V94e4G8Ufxx/kQftwaIFXE
N2Wp4T+6Uaoj0+jnGLMRMy3j4oHrB0m6Zz6ZOQYIPSZoZxRqSVEyltkqJn3QQp55
wmqvW4yXOnilf/MORf8lwdFGn3hZ/7jbs8DHXGWS/e3PQfS6zdrr
-----END RSA PRIVATE KEY-----
EOF
sudo cp /root/.ssh/id_rsa /home/heat-admin/.ssh/id_rsa
sudo chown heat-admin:heat-admin /home/heat-admin/.ssh/id_rsa
sudo chmod 400 /home/heat-admin/.ssh/id_rsa
sudo chmod 400 /root/.ssh/id_rsa
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC93x9G9fECs5LcvS6d2GaWqhw4x0/wJuLeRy2wh5zHwu6fJQQ7Xg1gTqzq4Eb/ddM8qCtxu9wU2rz5VsaZlH4QH6ns5nsexMCXX5HE556uOXGgpuVJGqv2WW3zOmyfFBy1FDxDWOT6UVZfy6G+at3ZxTbXYIuARvs5ije3mWUxfyiPZMdcb8JQvvMuaCD0is6t+47pXOZjJsfMy9B9V92MwqraB8e7LmLTyzfxxSPyB7xYZb4yYcFRiuzr/Pgik8UFNHMIy0nqGPQRs2w5Z5jbl0GfCB0aSLuBp668yDmd37sLfmIJ2MKbeZ8BtHsgP+bAoLH0h08/EBszBgnJ2FWH root@zion" > /root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC93x9G9fECs5LcvS6d2GaWqhw4x0/wJuLeRy2wh5zHwu6fJQQ7Xg1gTqzq4Eb/ddM8qCtxu9wU2rz5VsaZlH4QH6ns5nsexMCXX5HE556uOXGgpuVJGqv2WW3zOmyfFBy1FDxDWOT6UVZfy6G+at3ZxTbXYIuARvs5ije3mWUxfyiPZMdcb8JQvvMuaCD0is6t+47pXOZjJsfMy9B9V92MwqraB8e7LmLTyzfxxSPyB7xYZb4yYcFRiuzr/Pgik8UFNHMIy0nqGPQRs2w5Z5jbl0GfCB0aSLuBp668yDmd37sLfmIJ2MKbeZ8BtHsgP+bAoLH0h08/EBszBgnJ2FWH root@zion" > /home/heat-admin/.ssh/authorized_keys

/bin/hostnamectl | grep 'hostname' | grep ctrl- -q ;
#if [ $? == 0 ]; then
#
#    #Export OS values
#    #export OS_TOKEN=$(hiera "keystone::admin_token")
#    #export OS_URL=$(hiera "nova::api::identity_uri")/v2.0/
#
#    #cinder_user_id=$(openstack user show cinder -c id -f value)
#    #service_id=$(openstack project show service -c id -f value)
#
#    #openstack-config --set /etc/cinder/cinder.conf DEFAULT cinder_internal_tenant_project_id $service_id
#    #openstack-config --set /etc/cinder/cinder.conf DEFAULT cinder_internal_tenant_user_id $cinder_user_id
#
#    #cinder --os-username admin --os-tenant-name admin type-create iSCSI_NetApp
#    #cinder --os-username admin --os-tenant-name admin type-key iSCSI_NetApp set volume_backend_name=tripleo_iscsi
#
#    #cinder --os-username admin --os-tenant-name admin type-create NFS_NetApp
#    #cinder --os-username admin --os-tenant-name admin type-key NFS_NetApp set volume_backend_name=tripleo_netapp
#
## Create metadata file for Glance backend
#cat <<EOF >> /etc/glance/nfs-glance-metadata.json
#{
#    "id": "NFS-glance",
#    "share_location": "nfs://$GLANCE_NFS_EXPORT/$glance_nfs_export",
#    "mountpoint":"/var/lib/glance/images",
#    "type": "nfs"
#}
#EOF
#
#    # Set up path of the file in glance-api.conf file
#    openstack-config --set /etc/glance/glance-api.conf glance_store filesystem_store_metadata_file "/etc/glance/nfs-glance-metadata.json"
#
#    #cd /usr/bin/ && sudo curl -O http://$UNDERCLOUD_IP/$OFFLOAD_BIN
#
#    #if [ $? -eq 0 ]; then
#    #    chown cinder:cinder /usr/bin/$OFFLOAD_BIN
#    #    chmod +x /usr/bin/$OFFLOAD_BIN
#    #else
#    #    exit 1
#    #fi
#
#    # Restart Cinder & Glance services
#    if [[ $(hostname) =~ "$(hiera keystone::roles::first_controller_host)" ]]; then
#        pcs resource restart openstack-cinder-volume-clone $(hostname | sed 's/.localdomain//')
#        pcs resource restart openstack-cinder-api-clone $(hostname | sed 's/.localdomain//')
#        pcs resource restart openstack-glance-registry-clone $(hostname | sed 's/.localdomain//')
#        pcs resource restart openstack-glance-api-clone $(hostname | sed 's/.localdomain//')
#    fi
#
#   echo "`date` - NetApp post-deploy setup succeed"
#
#fi
