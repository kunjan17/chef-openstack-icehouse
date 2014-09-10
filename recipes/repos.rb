#
# Cookbook Name:: centos-cloud
# Recipe:: repos
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

cookbook_file "/etc/yum.repos.d/epel.repo" do
  source "epel.repo"
  mode "0644"
  owner "root"
  group "root"
  action :create_if_missing
end

cookbook_file "/etc/yum.repos.d/opendaylight.repo" do
  source "opendaylight.repo"
  mode "0644"
  owner "root"
  group "root"
  action :create_if_missing
end

cookbook_file "/etc/yum.repos.d/openstack-icehouse.repo" do
  action :create_if_missing
  source "openstack-icehouse.repo"
  mode "0644"
  owner "root"
  group "root"
end

# execute "yum clean all"
