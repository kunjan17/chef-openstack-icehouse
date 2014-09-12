#
# Cookbook Name:: centos_cloud
# Recipe:: sahara
#
# Copyright © 2014 Leonid Laboshin <laboshinl@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.
include_recipe "centos_cloud::common"
include_recipe "centos_cloud::mysql"

%w[openstack-sahara].each do |pkg|
  package pkg do
    action :install
  end
end

%w[openstack-sahara-api].each do |srv|
  service srv do
    action [:enable, :start]
  end
end

firewalld_rule "sahara" do
  action :set
  protocol "tcp"
  port %w[8386]
end

centos_cloud_database "sahara" do
  password node[:creds][:mysql_password]
end

template "/etc/sahara/sahara.conf" do
  source "sahara/sahara.conf.erb"
  notifies :restart, "service[openstack-sahara-api]"
end

execute "Populate sahara database" do
  command "sahara-db-manage --config-file /etc/sahara/sahara.conf upgrade head"
  action :nothing
end


