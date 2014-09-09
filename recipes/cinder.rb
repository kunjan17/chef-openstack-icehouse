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
include_recipe "firewalld"

libcloud_ssh_keys node[:creds][:ssh_keypair] do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

# Create database for cinder
centos_cloud_database "cinder" do
  password node[:creds][:mysql_password]
end

# Install cinder packages
%w[
  openstack-cinder targetcli].each do |pkg|
  package pkg do
    action :install
  end
end


# Configure service
centos_cloud_config "/etc/cinder/cinder.conf" do
  command [# Identity service connection
    "DEFAULT auth_strategy keystone",
    "DEFAULT notification_driver cinder.openstack.common.notifier.rpc_notifier",
    "DEFAULT control_exchange cinder",
    "DEFAULT iscsi_helper lioadm",
    "DEFAULT iscsi_ip_address 127.0.0.1",
    "DEFAULT osapi_volume_workers #{node[:cpu][:real]}",
    # Mysql connection
    "DEFAULT sql_connection mysql://cinder:" <<
    "#{node[:creds][:mysql_password]}@localhost/cinder",
    # Message broker
    "DEFAULT rpc_backend cinder.openstack.common.rpc.impl_kombu",
    "DEFAULT rabbit_host #{node[:ip][:rabbitmq]}",
    "DEFAULT rabbit_password #{node[:creds][:rabbitmq_password]}",
    # Multi backend
    "DEFAULT enabled_backends lvm",
    "lvm volume_driver cinder.volume.drivers.lvm.LVMISCSIDriver",
    "lvm volume_group  #{node[:auto][:volume_group]}",
    "lvm volume_backend_name  LVM_iSCSI",
    "keystone_authtoken auth_host #{node[:ip][:keystone]}",
    "keystone_authtoken admin_tenant_name admin",
    "keystone_authtoken admin_user admin",
    "keystone_authtoken admin_password " <<
    node[:creds][:admin_password],]
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
%w[3260 8776].each do |port|
  firewalld_rule port
end

# Populate database
execute "cinder-manage db sync"

# Enable services
%w[
target openstack-cinder-volume
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
