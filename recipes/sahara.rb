#
# Cookbook Name:: centos-cloud
# Recipe:: sahara
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::mysql"
include_recipe "centos_cloud::iptables-policy"
include_recipe "libcloud"

%w[openstack-sahara].each do |pkg|
  package pkg do
    action :install
  end
end

libcloud_ssh_keys "openstack" do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

simple_iptables_rule "sahara" do
  rule "-p tcp -m multiport --dports 8386"
  jump "ACCEPT"
end

centos_cloud_database "sahara" do
  password node[:creds][:mysql_password]
end

centos_cloud_config "/etc/sahara/sahara.conf" do
  command [" database connection mysql://sahara:#{node[:creds][:mysql_password]}@localhost/sahara",
    "DEFAULT os_auth_host #{node[:ip][:keystone]}",
    "DEFAULT os_auth_port 35357",
    "DEFAULT enable_notifications true",
    "DEFAULT notification_driver messaging",
    "DEFAULT rpc_backend rabbit",
    "DEFAULT rabbit_host #{node[:ip][:rabbitmq]}",
    "DEFAULT rabbit_password #{node[:creds][:rabbitmq_password]}",
    "DEFAULT os_admin_tenant_name admin",
    "DEFAULT os_admin_username admin",
    "DEFAULT os_admin_password #{node[:creds][:admin_password]}",
    "keystone_authtoken auth_uri http://#{node[:ip][:keystone]}:5000/v2.0/",
    "keystone_authtoken identity_uri http://#{node[:ip][:keystone]}:35357/",
    "keystone_authtoken admin_user admin",
    "keystone_authtoken admin_password #{node[:creds][:admin_password]}",
    "keystone_authtoken admin_tenant_name admin"
]
end

execute "sahara-db-manage --config-file /etc/sahara/sahara.conf upgrade head"

%w[openstack-sahara-api].each do |srv|
  service srv do
    action [:enable, :restart]
  end
end
