#
# Cookbook Name:: centos-cloud
# Recipe:: glance
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

# Install mysql-server if not exists
include_recipe "libcloud"
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::mysql"
include_recipe "centos_cloud::iptables-policy"

libcloud_ssh_keys node[:creds][:ssh_keypair] do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

# Create database
centos_cloud_database "glance" do
  password node[:creds][:mysql_password]
end

# Install packages
package "openstack-glance" do
  action :install
end

# Keystone & MySQL connection
%w[
/etc/glance/glance-api.conf
/etc/glance/glance-registry.conf
].each do |cfg|
  centos_cloud_config cfg do
    command ["database connection mysql://glance:" <<
      "#{node[:creds][:mysql_password]}@localhost/glance",
      "paste_deploy flavor keystone",
      "keystone_authtoken auth_host #{node[:ip][:keystone]}",
      "keystone_authtoken auth_port 35357",
      "keystone_authtoken auth_protocol http",
      "keystone_authtoken admin_tenant_name admin",
      "keystone_authtoken admin_user admin",
      "keystone_authtoken admin_password" <<
      " #{node[:creds][:admin_password]}"]
  end
end

centos_cloud_config "/etc/glance/glance-api.conf" do
  command ["DEFAULT default_store file",
    "DEFAULT swift_store_auth_address" <<
    " http://#{node[:ip][:keystone]}:5000/v2.0/",
    "DEFAULT swift_store_user admin:admin",
    "DEFAULT notifier_strategy qpid",
    "DEFAULT rpc_backend qpid",
    "DEFAULT qpid_hostname #{node[:ip][:qpid]}",
    "DEFAULT swift_store_create_container_on_put True",
    "DEFAULT swift_store_key #{node[:creds][:admin_password]}",
    "DEFAULT db_enforce_mysql_charset False"]
end

# Add iptables rule
simple_iptables_rule "glance" do
  rule "-p tcp -m multiport --dports 9292,9191"
  jump "ACCEPT"
end

# Populate database
execute "su glance -s /bin/sh -c 'glance-manage db_sync'" do
  action :run
end

# UFO (wrong privilegies on file regisry.log prevents service
# openstack-glance-registry from start)
file "/var/log/glance/registry.log" do
  action :create
  owner "glance"
  group "glance"
  mode "0644"
end

# Restart services
%w{openstack-glance-api openstack-glance-registry}.each do |srv|
  service srv do
    action [:enable, :restart]
  end
end

# Keystone authorization
libcloud_file_append "/root/.bashrc" do
  line ["# Keystone credentials",
    "export OS_USERNAME=admin",
    "export OS_TENANT_NAME=admin",
    "export OS_PASSWORD=#{node[:creds][:admin_password]}",
    "export OS_AUTH_URL=http://#{node[:ip][:keystone]}:35357/v2.0/"]
end

