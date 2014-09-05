#
# Cookbook Name:: centos-cloud
# Recipe:: dashboard
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

include_recipe "libcloud"
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::iptables-policy"

%w[
mod_wsgi httpd mod_ssl openstack-dashboard
memcached python-memcached python-django-sahara
].each do |pkg|
  package pkg do
    action :install
  end
end

simple_iptables_rule "dashboard" do
  rule "-p tcp -m multiport --dports 443"
  jump "ACCEPT"
end

template "/usr/share/openstack-dashboard/openstack_dashboard/settings.py" do 
  mode "0644"
  owner "root"
  group "root"
  source "dashboard/settings.py.erb"
end

template "/etc/openstack-dashboard/local_settings" do 
  mode "0640"
  owner "root"
  group "root"
  source "dashboard/local_settings.erb"
end

libcloud_file_append "/var/www/html/index.html" do
  line ["<head>",
    "<meta http-equiv='refresh' content='N; URL=/dashboard'>",
    "</head>"]
end

service "httpd" do
  action [:enable, :start]
end

