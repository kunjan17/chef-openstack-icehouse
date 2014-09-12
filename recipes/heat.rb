#
# Cookbook Name:: centos_cloud
# Recipe:: heat
#
# Copyright © 2014 Leonid Laboshin <laboshinl@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.

include_recipe "centos_cloud::common"
include_recipe "centos_cloud::mysql"

%w[
  openstack-heat-api 
  openstack-heat-api-cfn 
  openstack-heat-api-cloudwatch
  openstack-heat-common 
  openstack-heat-engine 
  openstack-heat-templates 
  python-heatclient
].each do |pkg|
  package pkg do
    action :install
  end
end

%w[
  openstack-heat-api 
  openstack-heat-api-cfn
  openstack-heat-api-cloudwatch 
  openstack-heat-engine
].each do |srv|
  service srv do
    action [:enable,:start]
  end
end

firewalld_rule "keystone" do
  action :set
  protocol "tcp"
  port %w[8000 8003 8004]
end

centos_cloud_database "heat" do
  password node[:creds][:mysql_password]
end

template "/etc/heat/heat.conf" do
  source "heat/heat.conf.erb"
  mode "0640"
  owner "root"
  group "heat"
  notifies :restart, "service[openstack-heat-api]"
  notifies :restart, "service[openstack-heat-api-cfn]"
  notifies :restart, "service[openstack-heat-api-cloudwatch]"
  notifies :restart, "service[openstack-heat-engine]"
end

execute "Populate heat database" do
  command "heat-manage db_sync"
  action :run
end


