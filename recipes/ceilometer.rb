#
# Cookbook Name:: centos_cloud
# Recipe:: ceilometer
#
# Copyright © 2014 Leonid Laboshin <laboshinl@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.

include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "firewalld"
include_recipe "libcloud"

libcloud_ssh_keys "openstack" do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

%w[
  openstack-ceilometer-api 
  openstack-ceilometer-central
  openstack-ceilometer-collector
].each do |srv|
  service srv do
    action [:enable]
  end
end

firewalld_rule "ceilometer" do
  action :set
  protocol "tcp"
  port ["8877","8822"]
end

%w[
  mongodb-server mongodb 
  openstack-ceilometer-api 
  openstack-ceilometer-collector
  openstack-ceilometer-central 
  python-ceilometerclient 
  python-ceilometer
].each do |pkg|
  package pkg do
    action :install
  end
end

service "mongod" do
  action [:enable,:restart]
end

execute %Q{mongo ceilometer --eval 'db.addUser("ceilometer","#{node[:creds][:mysql_password]}", false)'}

template "/etc/ceilometer/ceilometer.conf" do
  mode "0640"
  owner "root"
  group "ceilometer"
  source "ceilometer/ceilometer.conf.erb"
  notifies :restart, "service[openstack-ceilometer-api]"
  notifies :restart, "service[openstack-ceilometer-central]"
  notifies :restart, "service[openstack-ceilometer-collector]"
end

execute "ceilometer-dbsync"

