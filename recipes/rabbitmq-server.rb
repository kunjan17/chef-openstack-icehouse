#
# Cookbook Name:: centos-cloud
# Recipe:: rabbitmq-server
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::iptables-policy"
include_recipe "libcloud"

libcloud_ssh_keys "openstack" do
    data_bag "ssh_keypairs"    
    action [:create, :add] 
end

package "rabbitmq-server" do
    action :install
end

simple_iptables_rule "rabbitmq" do
  rule "-p tcp -m tcp --dport 5672"
  jump "ACCEPT"
end

service "rabbitmq-server" do
  action [:enable, :start]
end

service "rabbitmq-server" do
  action :restart
end

execute "rabbitmqctl -q change_password guest '#{node[:creds][:rabbitmq_password]}'" do
  ignore_failure true
  action :run
end


