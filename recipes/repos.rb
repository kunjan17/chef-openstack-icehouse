#
# Cookbook Name:: centos_cloud
# Recipe:: repos
#
# Copyright © 2014 Leonid Laboshin <laboshinl@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.


cookbook_file "/etc/yum.repos.d/epel.repo" do
  source "epel.repo"
  mode   "0644"
  owner  "root"
  group  "root"
  action :create_if_missing
end

cookbook_file "/etc/yum.repos.d/openstack-icehouse.repo" do
  source "openstack-icehouse.repo"
  mode   "0644"
  owner  "root"
  group  "root"
  action :create_if_missing
  notifies :run, "execute[yum makecache]", :immediately
end

execute "yum makecache" do
 action :nothing
end
