server_path=content/dist/rhel/server/7/7Server/x86_64
rhel_7_server_rpms=$server_path/os/
rhel_7_server_extras_rpms=$server_path/extras/os/
rhel_7_server_rh_common_rpms=$server_path/rh-common/os/
rhel_7_server_satellite_tools_6_2_rpms=$server_path/sat-tools/
rhel_ha_for_rhel_7_server_rpms=$server_path/highavailability/os/
rhel_7_server_openstack_10_rpms=$server_path/openstack/10/os/
rhel_7_server_rhceph_2_osd_rpms=$server_path/ceph-osd/2/os/
rhel_7_server_rhceph_2_mon_rpms=$server_path/ceph-mon/2/os/
rhel_7_server_rhceph_2_ools_rpms=$server_path/ceph-tools/2/os/
repo_list=(rhel-7-server-rpms rhel-7-server-extras-rpms rhel-7-server-rh-common-rpms rhel-7-server-satellite-tools-6.2-rpms rhel-ha-for-rhel-7-server-rpms rhel-7-server-openstack-10-rpms rhel-7-server-rhceph-2-osd-rpms rhel-7-server-rhceph-2-mon-rpms rhel-7-server-rhceph-2-tools-rpms)
repo_path=($rhel_7_server_rpms $rhel_7_server_extras_rpms $rhel_7_server_rh_common_rpms $rhel_7_server_satellite_tools_6_2_rpms $rhel_ha_for_rhel_7_server_rpms $rhel_7_server_openstack_10_rpms $rhel_7_server_rhceph_2_osd_rpms $rhel_7_server_rhceph_2_mon_rpms $rhel_7_server_rhceph_2_ools_rpms)

yum install -y yum-utils createrepo

sync_repos(){
  for i in {0..8}; do
    echo reposync --norepopath -d -r ${repo_list[$i]} -p ${repo_path[$i]}
    echo createrepo -v ${repo_path[$i]}
  done
}
get_content_isos(){
  for i in `grep "sat-6-isos--openstack-10\|sat-6-isos--rhel-7-server-x86_64" content | grep https | awk '{print $3}' | grep -o "https.*" | tr -d \"` ; do
    name=`echo $i| grep -o sat-6-isos.*.iso`
    sha=`echo $i | awk -F "/" '{print $10}'`
    echo $name $sha >> checksum
    echo wget -c $i -O $name -q --show-progress &
  done
}

verify_checksum(){
  while read i; do
    file=`echo $i | awk '{print $1}'`
    valid_checksum=`echo $i | awk '{print $2}'`
    actual_checksum=`shasum -a 256 $file | awk '{print $1}'`
    if [ "$actual_checksum" == "$valid_checksum" ]; then
      echo "File $file OK"
    else
      echo "File $file NOT OK"
    fi
  done < checksum
}

create_repo_file(){
  server=172.16.102.100
  echo "" > myrepo.repo
  additional_path="pub/cont/"
  for i in {0..8}; do
    echo [${repo_list[$i]}] >> myrepo.repo
    echo "baseurl = http://$server/$additional_path${repo_path[$i]}" >> myrepo.repo
    echo "name = ${repo_list[$i]}" >> myrepo.repo
  done
}

unpack_content(){
  for i in  `ls | grep iso`; do
    echo "Processing $i"
    mkdir /tmp/iso
    mount $i /tmp/iso
    cp -vr /tmp/iso /mnt/SatelliteISOs/
    umount /tmp/iso
  done
}
