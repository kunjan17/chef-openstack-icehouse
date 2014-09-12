#
# Cookbook Name:: centos_cloud
# Recipe:: nova
#
# Copyright © 2014 Leonid Laboshin <laboshinl@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.

include_recipe "tar"
include_recipe "centos_cloud::common"
include_recipe "centos_cloud::mysql"
include_recipe "centos_cloud::dashboard"

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
    action [:enable,:start]
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

