#!/bin/bash
# A heat-config-script which runs post-deploy actions for Cinder and Glance NetApp configuration.
# Inputs:
#   NETAPP_ID - ID of NetApp
#   NETAPP_IP - IP of the NetApp
#   NETAPP_EXPORT_FOLDER - Share folder name of NetApp for Glance
#   UNDERCLOUD_IP - IP of the Undercloud
#   OFFLOAD_BIN - Name of the Copy Offload binary

echo "Post deploy" > /root/test_file
sudo timedatectl set-timezone Europe/Bucharest


/bin/hostnamectl | grep 'hostname' | grep ctrl- -q ;
if [ $? == 0 ]; then

    #Export OS values
    #export OS_TOKEN=$(hiera "keystone::admin_token")
    #export OS_URL=$(hiera "nova::api::identity_uri")/v2.0/

    #cinder_user_id=$(openstack user show cinder -c id -f value)
    #service_id=$(openstack project show service -c id -f value)

    #openstack-config --set /etc/cinder/cinder.conf DEFAULT cinder_internal_tenant_project_id $service_id
    #openstack-config --set /etc/cinder/cinder.conf DEFAULT cinder_internal_tenant_user_id $cinder_user_id

    #cinder --os-username admin --os-tenant-name admin type-create iSCSI_NetApp
    #cinder --os-username admin --os-tenant-name admin type-key iSCSI_NetApp set volume_backend_name=tripleo_iscsi

    #cinder --os-username admin --os-tenant-name admin type-create NFS_NetApp
    #cinder --os-username admin --os-tenant-name admin type-key NFS_NetApp set volume_backend_name=tripleo_netapp

# Create metadata file for Glance backend
cat <<EOF >> /etc/glance/nfs-glance-metadata.json
{
    "id": "NFS-glance",
    "share_location": "nfs://$glance_nfs_export",
    "mountpoint":"/var/lib/glance/images",
    "type": "nfs"
}
EOF

    # Set up path of the file in glance-api.conf file
    openstack-config --set /etc/glance/glance-api.conf glance_store filesystem_store_metadata_file "/etc/glance/nfs-glance-metadata.json"

    #cd /usr/bin/ && sudo curl -O http://$UNDERCLOUD_IP/$OFFLOAD_BIN

    #if [ $? -eq 0 ]; then
    #    chown cinder:cinder /usr/bin/$OFFLOAD_BIN
    #    chmod +x /usr/bin/$OFFLOAD_BIN
    #else
    #    exit 1
    #fi

    # Restart Cinder & Glance services
    if [[ $(hostname) =~ "$(hiera keystone::roles::first_controller_host)" ]]; then
        pcs resource restart openstack-cinder-volume-clone $(hostname | sed 's/.localdomain//')
        pcs resource restart openstack-cinder-api-clone $(hostname | sed 's/.localdomain//')
        pcs resource restart openstack-glance-registry-clone $(hostname | sed 's/.localdomain//')
        pcs resource restart openstack-glance-api-clone $(hostname | sed 's/.localdomain//')
    fi

   echo "`date` - NetApp post-deploy setup succeed"

fi
