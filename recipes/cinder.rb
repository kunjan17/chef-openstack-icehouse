#
# Cookbook Name:: centos-cloud
# Recipe:: cinder
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "libcloud"
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::mysql"
include_recipe "centos_cloud::mysql"
include_recipe "centos_cloud::iptables-policy"

libcloud_ssh_keys node[:creds][:ssh_keypair] do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

# Create database for cinder
centos_cloud_database "cinder" do
  password node[:creds][:mysql_password]
end

# Install cinder packages
%w[openstack-cinder iscsi-initiator-utils scsi-target-utils].each do |pkg|
  package pkg do
    action :install
  end
end


# Configure service
centos_cloud_config "/etc/cinder/cinder.conf" do
  command [# Identity service connection
    "DEFAULT auth_strategy keystone",
    "DEFAULT notification_driver cinder.openstack.common.notifier.rabbit_notifier",
    "DEFAULT control_exchange cinder",
    "keystone_authtoken auth_host #{node[:ip][:keystone]}",
    "keystone_authtoken admin_tenant_name admin",
    "keystone_authtoken admin_user admin",
    "keystone_authtoken admin_password " <<
    node[:creds][:admin_password],
    # Mysql connection
    "DEFAULT sql_connection mysql://cinder:" <<
    "#{node[:creds][:mysql_password]}@localhost/cinder",
    # Message broker
    "DEFAULT rpc_backend cinder.openstack.common.rpc.impl_qpid",
    "DEFAULT qpid_hostname #{node[:ip][:qpid]}",
    # Multi backend
#    "DEFAULT enabled_backends lvm,nexenta",
    "DEFAULT enabled_backends lvm",
    "lvm volume_driver cinder.volume.drivers.lvm.LVMISCSIDriver",
    "lvm volume_group  #{node[:auto][:volume_group]}",
    "lvm volume_backend_name  LVM_iSCSI",
    "nexenta nexenta_rest_port 80",
    "nexenta volume_driver cinder.volume.drivers.nexenta.volume.NexentaDriver",
    "nexenta nexenta_volume main",
    "nexenta nexenta_host 195.208.117.178",
    "nexenta nexenta_password vBh!3dFv",
    "nexenta nexenta_user admin",
    "nexenta volume_backend_name Nexenta_iSCSI",]
end

centos_cloud_config "/etc/cinder/api-paste.ini" do
  command ["filter:authtoken service_host #{node[:ip][:keystone]}",
    "filter:authtoken auth_host #{node[:ip][:keystone]}",
    "filter:authtoken auth_uri" <<
    "http://#{node[:ip][:keystone]}:35357/v2.0",
    "filter:authtoken admin_tenant_name admin",
    "filter:authtoken admin_user admin",
    "filter:authtoken admin_password" <<
    " #{node[:creds][:admin_password]}"]
end

# Accept incoming connections on glance ports
simple_iptables_rule "cinder" do
  rule "-p tcp -m multiport --dports 3260,8776"
  jump "ACCEPT"
end

#libcloud_file_append "/etc/tgt/targets.conf" do
#  line "include /etc/cinder/volumes/*"
#end
#
#libcloud_file_append "/etc/tgt/targets.conf" do
#  line "include /etc/cinder/volumes/*"
#end

#libcloud_file_append "/etc/tgt/conf.d/cinder.conf" do
#  line "include /etc/cinder/volumes/*"
#end

# Populate database
execute "cinder-manage db sync"

# Enable services
%w[
tgtd openstack-cinder-volume
openstack-cinder-scheduler openstack-cinder-api
].each do |srv|
  service srv do
    action [:enable, :restart]
  end
end

#execute "cinder type-create lvm" do
#  not_if "cinder type-list | grep lvm"
#  action :run
#end

#execute "cinder type-key lvm set volume_backend_name=LVM_iSCSI" do
#  not_if "cinder extra-specs-list | grep LVM_iSCSI"
#  action :run
#end

#execute "cinder type-create nexenta" do
#  not_if "cinder type-list | grep nexenta" 
#  action :run
#end

#execute "cinder type-key nexenta set volume_backend_name=Nexenta_iSCSI" do
#  not_if "cinder extra-specs-list | grep Nexenta_iSCSI"
#  action :run
#end