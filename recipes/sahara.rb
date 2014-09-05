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
  command [" database connection mysql://heat:#{node[:creds][:mysql_password]}@localhost/sahara",
    "DEFAULT os_auth_host #{node[:ip][:keystone]}",
    "DEFAULT os_auth_port 35357",
    "DEFAULT os_admin_tenant_name admin",
    "DEFAULT os_admin_username admin",
    "DEFAULT os_admin_password #{node[:creds][:admin_password]}"]
end

execute "sahara-db-manage --config-file /etc/sahara/sahara.conf upgrade head"

%w[openstack-heat-api openstack-heat-api-cfn
openstack-heat-api-cloudwatch openstack-heat-engine].each do |srv|
  service srv do
    action [:enable, :restart]
  end
end
