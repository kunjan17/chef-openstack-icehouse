#
# Cookbook Name:: centos_cloud
# Recipe:: swift-proxy
#
# Copyright © 2014 Leonid Laboshin <laboshinl@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.


include_recipe "centos_cloud::common"

%w[
  memcached 
  openstack-swift-proxy
  python-keystoneclient
].each do |pkg|
  package pkg do
    action :install
  end
end

template "/etc/swift/proxy-server.conf" do
  source "swift/proxy-server.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
  notifies :restart, "service[openstack-swift-proxy]"
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
%w[
memcached 
openstack-swift-proxy
].each do |srv|
  service srv do
    action [:enable, :restart]
  end
end

firewalld_rule "swift-proxy" do
  action :set
  protocol "tcp"
  port %w[8080]
end

