#
# Cookbook Name:: patch
# Recipe:: repos
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

cookbook_file "/tmp/config.patch" do
  source "config.py.patch01"
  mode "0644"
  owner "root"
  group "root"
end

cookbook_file "/tmp/driver.patch" do
  source "driver.py.patch01"
  mode "0644"
  owner "root"
  group "root"
end

cookbook_file "/tmp/manager.patch" do
  source "manager.py.patch01"
  mode "0644"
  owner "root"
  group "root"
end

cookbook_file "/usr/lib/python2.6/site-packages/nova/cmd/spicehttpproxy.py" do
  source "spicehttpproxy_cmd.py"
  mode "0644"
  owner "root"
  group "root"
end

cookbook_file "/usr/lib/python2.6/site-packages/nova/console/spicehttpproxy.py" do
  source "spicehttpproxy_console.py"
  mode "0644"
  owner "root"
  group "root"
end

cookbook_file "/usr/bin/nova-spicehttpproxy" do
  source "nova-spicehttpproxy"
  mode "0755"
  owner "root"
  group "root"
end

cookbook_file "/etc/init.d/openstack-nova-spicehttpproxy" do
  source "openstack-nova-spicehttpproxy"
  mode "0755"
  owner "root"
  group "root"
end

%w[driver config manager].each do |patch|
  execute "patch -p0 -s -N < /tmp/" + patch + ".patch" do
    ignore_failure true
  end
end

%w[
openstack-nova-spicehtml5proxy openstack-nova-spicehttpproxy 
openstack-nova-api openstack-nova-scheduler openstack-nova-conductor
openstack-nova-console openstack-nova-consoleauth
openstack-nova-cert
].each do |srv|
  service srv do
    only_if("ifconfig | grep #{node[:ip][:controller]}'\s'")
    action [:enable, :restart]
  end
end

service "openstack-nova-compute" do
  ignore_failure true
  action :restart
end
