#
# Cookbook Name:: centos_cloud
# Recipe:: keystone
#
# Copyright © 2014 Leonid Laboshin <laboshinl@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.

include_recipe "centos_cloud::common"
include_recipe "centos_cloud::mysql"

# Open keystone-related ports
firewalld_rule "keystone" do
  action :set
  protocol "tcp"
  port %w[5000 35357]
end

# Install MySQL, create database
centos_cloud_database "keystone" do
  password node[:creds][:mysql_password]
end

# Install packages
%w[
  openstack-keystone 
  python-paste-deploy
].each do |pkg|
  package pkg do
    action :install
  end
end

service "openstack-keystone" do
  action [:enable, :start]
end

# Configure service
template "/etc/keystone/keystone.conf" do
  mode "0640"
  owner "root"
  group "keystone"
  notifies :restart, "service[openstack-keystone]"
  source "keystone/keystone.conf.erb"
  notifies :restart, "service[openstack-keystone]", :immediately 
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

## Wait for keystone to start
libcloud_api_wait node[:ip][:keystone] do
  port "35357"
end

execute "keystone create admin user" do
  command "keystone bootstrap "<<
           "--pass #{node[:creds][:admin_password]}"
  environment ({
    'OS_SERVICE_TOKEN' => node[:creds][:keystone_token],
    'OS_SERVICE_ENDPOINT' => 'http://' + node[:ip][:keystone] + ':35357/v2.0'
  })
  not_if ("keystone user-list | grep admin")
  action :run
end

[
  "keystone role-create --name Member || :",
  "keystone role-create --name ResellerAdmin || :",
  "keystone user-role-add --user admin --role-id ResellerAdmin --tenant-id admin || :"
].each do |cmd|
  execute cmd do
    environment ({
      'OS_SERVICE_TOKEN' => node[:creds][:keystone_token],
      'OS_SERVICE_ENDPOINT' => 'http://' + node[:ip][:keystone] + ':35357/v2.0'
    })
    action :run
  end
end

execute "keystone update admin password" do
  command "keystone user-password-update "<<
           "--pass #{node[:creds][:admin_password]} admin"
  environment ({
    'OS_SERVICE_TOKEN' => node[:creds][:keystone_token],
    'OS_SERVICE_ENDPOINT' => 'http://' + node[:ip][:keystone] + ':35357/v2.0'
  })
  action :run
end
