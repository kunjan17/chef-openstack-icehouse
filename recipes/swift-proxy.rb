#
# Cookbook Name:: centos-cloud
# Recipe:: swift-proxy
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

# Adding epel & openstack repos
include_recipe "selinux::disabled"
include_recipe "libcloud"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::iptables-policy"
include_recipe "centos_cloud::keystone-credentials"

libcloud_ssh_keys node[:creds][:ssh_keypair] do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

%w[memcached openstack-swift-proxy python-keystoneclient].each do |pkg|
  package pkg do
    action :install
  end
end

centos_cloud_config "/etc/swift/proxy-server.conf" do
  command [
    "filter:authtoken admin_tenant_name admin",
    "filter:authtoken admin_user admin",
    "filter:authtoken admin_password #{node[:creds][:admin_password]}",
    "filter:authtoken auth_host #{node[:ip][:keystone]}",
    "filter:authtoken auth_port 35357",
    "filter:authtoken auth_protocol http",
    "filter:authtoken auth_uri http://#{node[:ip][:keystone]}:5000",
    "filter:keystone operator_roles admin,Member",
    "filter:ceilometer use egg:ceilometer#swift"
  ]
end

centos_cloud_config "/etc/swift/swift.conf" do
  command "swift-hash swift_hash_path_suffix #{node[:creds][:swift_hash]}"
end

%w[object container account].each do |cmd|
  execute "swift-ring-builder "+ cmd +".builder create 10 1 1" do
    cwd "/etc/swift"
  end
end

directory "/tmp/keystone-signing-swift" do
  owner "swift"
  group "swift"
  mode "0755"
  action :create
end

# Proxy failes to start until there is at least one node, it's pretty normal
%w[memcached openstack-swift-proxy].each do |srv|
  service srv do
    action [:enable, :restart]
  end
end

# Allow swift-proxy related packets
simple_iptables_rule "swift-proxy" do
  rule "-p tcp -m multiport --dports 8080"
  jump "ACCEPT"
end

simple_iptables_rule "memcached" do
  rule "-p tcp -m multiport --dports 11211"
  jump "ACCEPT"
end

