#
# Cookbook Name:: centos-cloud
# Recipe:: swift-node
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "libcloud"
include_recipe "lvm"
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::iptables-policy"
include_recipe "centos_cloud::keystone-credentials"

libcloud_ssh_keys node[:creds][:ssh_keypair] do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

%w[
xfsprogs
openstack-swift-object
openstack-swift-container
openstack-swift-account
].each do |pkg|
  package pkg do
    action :install
  end
end

%w[/srv/node/ /srv/node/device].each do |dir|
  directory dir do
    mode "0755"
    owner "swift"
    group "swift"
    action :create
    recursive true
  end
end

#REMOVE ME!!
cookbook_file "/tmp/lvm_fix.sh" do
  owner "root"
  group "root"
  mode "0755"
  action :create
  source "lvm_fix.sh"
end

execute "bash /tmp/lvm_fix.sh" do
  ignore_failure true
end

lvm_logical_volume "swift" do 
  group node[:auto][:volume_group]
  size '25%VG' 
  filesystem 'xfs' 
  mount_point '/srv/node/device/' 
end 
  
simple_iptables_rule "swift-node" do
  rule "-p tcp -m multiport --dports 6000,6001,6002,873"
  jump "ACCEPT"
end

centos_cloud_config "/etc/swift/swift.conf" do
  command "swift-hash swift_hash_path_suffix #{node[:creds][:swift_hash]}"
end

%w[object account container].each do |cfg|
  centos_cloud_config "/etc/swift/" + cfg + "-server.conf" do
    command "DEFAULT bind_ip #{node[:ipaddress]}"
  end
end

# Add rings and rebalance
libcloud_ssh_command "manage rings" do
  server node[:ip][:swift]
  command [
    "swift-ring-builder /etc/swift/object.builder" <<
    " add r1z1-#{node[:ipaddress]}:6000/device 1",
    "swift-ring-builder /etc/swift/object.builder rebalance",
    "swift-ring-builder /etc/swift/container.builder" <<
    " add r1z1-#{node[:ipaddress]}:6001/device 1",
    "swift-ring-builder /etc/swift/container.builder rebalance",
    "swift-ring-builder /etc/swift/account.builder" <<
    " add r1z1-#{node[:ipaddress]}:6002/device 1",
    "swift-ring-builder /etc/swift/account.builder rebalance",
    "chown -R swift.swift /etc/swift"
  ]
end

# Copy ring files from proxy server
%w[ container.ring.gz account.ring.gz object.ring.gz ].each do |file|
  libcloud_file_scp "/etc/swift/"+file do
    not_if do
      node[:ip][:swift] == node[:auto][:internal_ip]
    end
    server node[:ip][:swift]
    remote_path "/etc/swift/"+file
  end
end
# Start proxy remotely
libcloud_ssh_command "service openstack-swift-proxy restart" do
  server node[:ip][:swift]
end

execute "chown -R swift.swift /etc/swift "

# Enable services
%w[
openstack-swift-account
openstack-swift-container
openstack-swift-object
].each do |srv|
  service srv do
    action [:enable, :restart]
  end
end

