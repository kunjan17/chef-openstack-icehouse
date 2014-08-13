#
# Cookbook Name:: centos-cloud
# Recipe:: qpid
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

package "qpid-cpp-server" do
    action :install
end

#execute "sed -i -e 's/auth=.*/auth=no/g' /etc/qpidd.conf"

libcloud_file_append "/etc/qpidd.conf" do
  line ["auth=no"]
end

simple_iptables_rule "mysql" do
  rule "-p tcp -m tcp --dport 5672"
  jump "ACCEPT"
end

service "qpidd" do
    action [:enable, :start]
end
