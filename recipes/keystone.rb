#
# Cookbook Name:: centos-cloud
# Recipe:: keystone
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::mysql"
include_recipe "centos_cloud::iptables-policy"
include_recipe "centos_cloud::keystone-credentials"
include_recipe "libcloud"

# Open keystone-related ports
simple_iptables_rule "keystone" do
  rule "-p tcp -m multiport --dports 5000,35357"
  jump "ACCEPT"
end

# Create id_rsa, id_rsa.pub, add id_rsa.pub to autorized_keys
libcloud_ssh_keys node[:creds][:ssh_keypair] do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

# Install MySQL, create database
centos_cloud_database "keystone" do
  password node[:creds][:mysql_password]
end

# Install package
#%w[openstack-keystone python-paste-deploy pyhton-six].each do |pkg|
%w[openstack-keystone python-paste-deploy].each do |pkg|
  package pkg do
    action :install
  end
end

# Configure service
centos_cloud_config "/etc/keystone/keystone.conf" do
  command [
    "DEFAULT admin_token #{node[:creds][:keystone_token]}",
    "sql connection mysql://keystone:#{node[:creds][:mysql_password]}"<<
    "@#{node[:ip][:keystone]}/keystone",
    "catalog driver keystone.catalog.backends.templated.TemplatedCatalog"
  ]
end

# Template for creating services and endpoints
template "/etc/keystone/default_catalog.templates" do
  source "keystone/default_catalog.templates.erb"
  owner "root"
  group "keystone"
  mode "0640"
end

# BUG_FIX: This file is nessesary for starting service
file "/var/log/keystone/keystone.log" do
  action :create
  owner "keystone"
  group "keystone"
  mode "0644"
end

# Create dir for certs
directory "/etc/keystone/ssl" do
  owner "keystone"
  group "keystone"
  mode "0755"
  action :create
end

# Populate keystone database
execute "su keystone -s /bin/sh -c 'keystone-manage db_sync'" do
  action :run
end

# Generate certs
execute "su keystone -s /bin/sh -c 'keystone-manage pki_setup'" do
  action :run
end

# Start service
service "openstack-keystone" do
  action [:enable, :restart]
end

# Wait for keystone to start
libcloud_api_wait node[:ip][:keystone] do
  port "35357"
end

# Create admin user
[
  "keystone user-create --name=admin --pass=#{node[:creds][:admin_password]}",
  "keystone role-create --name=admin",
  "keystone role-create --name=Member",
  "keystone role-create --name=ResellerAdmin",
  "keystone tenant-create --name=admin",
  "keystone user-role-add --user admin --role-id admin --tenant-id admin",
  "keystone user-role-add --user admin --role-id ResellerAdmin --tenant-id admin"
].each do |cmd|
  execute cmd do
    ignore_failure true
    environment ({
      'OS_SERVICE_TOKEN' => node[:creds][:keystone_token],
      'OS_SERVICE_ENDPOINT' => 'http://' + node[:ip][:keystone] + ':35357/v2.0'
    })
    action :run
  end
end
