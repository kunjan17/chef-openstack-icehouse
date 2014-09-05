#
# Cookbook Name:: centos-cloud
# Recipe:: mysql
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "centos_cloud::iptables-policy"

%w{mariadb-galera-server MySQL-python}.each  do |pkg|
  package pkg do
    action :install
  end
end

centos_cloud_config "/etc/my.cnf.d/server.cnf " do
    command ["mysqld bind-address #{node[:auto][:internal_ip]}",
             "mysqld innodb_file_per_table",
             "mysqld innodb_flush_method O_DIRECT",
             "mysqld innodb_log_file_size 25M",
             "mysqld innodb_buffer_pool_size 225M"]
end

service "mariadb" do
  action [:enable, :restart]
end

simple_iptables_rule "mysql" do
  rule "-p tcp -m multiport --dports 3306"
  jump "ACCEPT"
end

execute "mysqladmin -uroot password '#{node[:creds][:mysql_password]}'" do
  ignore_failure true
  action :run
end
