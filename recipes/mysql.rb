#
# Cookbook Name:: centos-cloud
# Recipe:: mysql
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "firewalld"

%w{
mariadb-galera-server 
MySQL-python
}.each  do |pkg|
  package pkg do
    action :install
  end
end

service "mariadb" do
  action [:enable]
end

template "/etc/my.cnf.d/server.cnf " do
    source "mariadb/server.cnf.erb"
    notifies :restart, "service[mariadb]"
end

firewalld_rule "mysql" do
  action :set
  protocol "tcp"
  port "3306"
end

execute "mysqladmin -uroot password '#{node[:creds][:mysql_password]}'" do
  ignore_failure true
  action :run
end
