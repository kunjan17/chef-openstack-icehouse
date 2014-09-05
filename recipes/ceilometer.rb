#
# Cookbook Name:: centos-cloud
# Recipe:: heat
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
#  Need to merge patches https://github.com/rcbops-cookbooks/ceilometer/tree/master/templates/default/patches
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::mysql"
include_recipe "centos_cloud::iptables-policy"
include_recipe "libcloud"

centos_cloud_database "ceilometer" do
  password node[:creds][:mysql_password]
end

libcloud_ssh_keys "openstack" do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

simple_iptables_rule "ceilometer" do
  rule "-p tcp -m multiport --dports 8777"
  jump "ACCEPT"
end

%w[openstack-ceilometer-api openstack-ceilometer-collector
openstack-ceilometer-central python-ceilometerclient
].each do |pkg|
  package pkg do
    action :install
  end
end

centos_cloud_config "/etc/ceilometer/ceilometer.conf" do
  command [#"DEFAULT rpc_backend ceilometer.openstack.common.rpc.impl_qpid",
    "DEFAULT rpc_backend cinder.openstack.common.rpc.impl_kombu",
    "DEFAULT rabbit_host #{node[:ip][:rabbitmq]}",
    "DEFAULT rabbit_password #{node[:creds][:rabbitmq-password]}",
    "DEFAULT log_dir /var/log/ceilometer",
#    "DEFAULT qpid_hostname #{node[:ip][:qpid]}",
    "database connection mysql://ceilometer:#{node[:creds][:mysql_password]}@localhost/ceilometer",
    "publisher_rpc metering_secret #{node[:creds][:metering_secret]}",
    "keystone_authtoken service_host #{node[:ip][:keystone]}",
    "keystone_authtoken auth_host #{node[:ip][:keystone]}",
    "keystone_authtoken auth_uri http://#{node[:ip][:keystone]}:35357/v2.0",
    "keystone_authtoken admin_tenant_name admin",
    "keystone_authtoken admin_user admin",
    "keystone_authtoken auth_port 35357",
    "keystone_authtoken auth_protocol http",
    "keystone_authtoken admin_password #{node[:creds][:admin_password]}",
    "service_credentials os_password #{node[:creds][:admin_password]}",
    "service_credentials os_auth_url http://#{node[:ip][:keystone]}:35357/v2.0",
    "service_credentials os_username admin",
    "service_credentials os_tenant_name admin"
  ]
end

execute "ceilometer-dbsync"

%w[openstack-ceilometer-api openstack-ceilometer-central
openstack-ceilometer-collector
].each do |srv|
  service srv do
    action [:enable, :restart]
  end
end

