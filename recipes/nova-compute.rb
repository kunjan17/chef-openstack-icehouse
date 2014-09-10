#
# Cookbook Name:: centos-cloud
# Recipe:: nova-compute
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

include_recipe "libcloud::ssh_key"
include_recipe "centos_cloud::selinux"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::openvswitch"
include_recipe "firewalld"

%w[openstack-nova-compute 
   openstack-ceilometer-compute
].each do |srv|
  package srv do
    action :install
  end
  service srv do 
    action :enable
  end
end

firewalld_rule "nova-compute" do
  action :set
  protocol "tcp"
  port %w[5900-5999 6080 6081 6082]
end


libcloud_ssh_keys node[:creds][:ssh_keypair] do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

template "/etc/nova/nova.conf" do
  mode   "0644"
  owner  "root"
  group  "root"
  source "nova/nova.conf.erb"
  notifies :restart, "service[openstack-nova-compute]"
end


template "/etc/ceilometer/ceilometer.conf" do
  mode   "0640"
  owner  "root"
  group  "ceilometer"
  source "ceilometer/ceilometer.conf.erb"
  notifies :restart, "service[openstack-ceilometer-compute]"
end

execute "virsh net-destroy default" do
  only_if("virsh net-list | grep default")
  action :run
end

execute "virsh net-undefine default" do
  only_if("virsh net-list --all| grep default")
  action :run
end
