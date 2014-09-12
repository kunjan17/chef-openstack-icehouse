#
# Cookbook Name:: centos_cloud
# Recipe:: ceilometer
#
# Copyright © 2014 Leonid Laboshin <laboshinl@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.

include_recipe "centos_cloud::common"

package "rabbitmq-server" do
  action :install
  notifies :run, "execute[Fix rabbit first start]", :immediately
end

firewalld_rule "keystone" do
  action :set
  protocol "tcp"
  port "5672"
end

service "rabbitmq-server" do
  action [:enable, :start]
end

execute "Fix rabbit first start" do
  command "rabbitmqctl status || : "
  action :nothing
  notifies :restart, "service[rabbitmq-server]", :immediately
end

execute "rabbitmqctl -q change_password guest '#{node[:creds][:rabbitmq_password]}'" do
  action :run
end

