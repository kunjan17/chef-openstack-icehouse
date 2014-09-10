#
# Cookbook Name:: centos_cloud
# Recipe:: selinux
#
# Copyright © 2014 Leonid Laboshin <laboshinl@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.

template "/etc/selinux/config" do
  source "selinux/selinux.erb"
end

execute "disable selinux without reboot" do
  command "setenforce 0"
  action :run
  not_if "getenforce | grep Disabled"
end
