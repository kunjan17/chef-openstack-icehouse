#
# Cookbook Name:: centos_cloud
# Recipe:: ntp-server
#
# Copyright © 2014 Leonid Laboshin <laboshinl@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.

include_recipe "centos_cloud::common"

package "ntp" do
    action :install
end

service "ntpd" do
 action :enable
end

firewalld_rule "swift-proxy" do
  action :set
  protocol "tcp"
  port %w[123]
end


template "/etc/ntp.conf" do
  source "ntp/ntp.conf.erb"
  mode "0644"
  owner "root"
  group "root"
  notifies :restart, "service[ntpd]"
end

template "/etc/ntp/step-tickers" do
  source "ntp/step-tickers.erb"
  mode "0644"
  owner "root"
  group "root"
  notifies :restart, "service[ntpd]"
end

