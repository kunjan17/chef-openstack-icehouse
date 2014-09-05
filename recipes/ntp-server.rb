#
# Cookbook Name:: centos-cloud
# Recipe:: ntp-server
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "centos_cloud::repos"
include_recipe "libcloud"


package "ntp" do
    action :install
end

simple_iptables_rule "ntp" do
  rule "--proto tcp --dport 123"
  jump "ACCEPT"
end

template "/etc/ntp.conf" do
  source "ntp/ntp.conf.erb"
  mode "0644"
  owner "root"
  group "root"
end

template "/etc/ntp/step-tickers" do
  source "ntp/step-tickers.erb"
  mode "0644"
  owner "root"
  group "root"
end

service "ntpd" do
  action [:enable,:restart]
end
