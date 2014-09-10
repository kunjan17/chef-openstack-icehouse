#
# Cookbook Name:: centos-cloud
# Recipe:: nova
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "tar"
include_recipe "libcloud::ssh_key"
include_recipe "centos_cloud::selinux"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::mysql"
include_recipe "firewalld"
include_recipe "centos_cloud::dashboard"

libcloud_ssh_keys node[:creds][:ssh_keypair] do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

centos_cloud_database "nova" do
  password node[:creds][:mysql_password]
end

%w[
  openstack-nova-api 
  openstack-nova-scheduler
  openstack-nova-conductor 
  openstack-nova-console
  openstack-nova-cert 
  openstack-nova-novncproxy
].each do |srv|
  package srv do
    action :install
  end
  service srv do
    action :enable
  end
end

template "/etc/nova/nova.conf" do
  mode   "0644"
  owner  "root"
  group  "root"
  source "nova/nova.conf.erb"
  notifies :restart, "service[openstack-nova-api]"
  notifies :restart, "service[openstack-nova-scheduler]"
  notifies :restart, "service[openstack-nova-conductor]"
  notifies :restart, "service[openstack-nova-console]"
  notifies :restart, "service[openstack-nova-cert]"
  notifies :restart, "service[openstack-nova-novncproxy]"
end

firewalld_rule "nova-compute" do
  action :set
  protocol "tcp"
  port %w[8773 8774 8775 6082]
end

execute "Populate nova database" do 
  command %Q[su nova -s /bin/sh -c "/usr/bin/nova-manage db sync"]
  action :run
end

