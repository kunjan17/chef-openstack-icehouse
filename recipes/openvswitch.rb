#
# Cookbook Name:: centos-cloud
# Recipe:: openvswitch
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

include_recipe "centos_cloud::selinux"
include_recipe "centos_cloud::repos"
include_recipe "firewalld"
include_recipe "libcloud"

%w[
  iproute 
  kernel
].each do |pkg|
  package pkg do
    action :upgrade
  end
end

%w[
  openstack-neutron-openvswitch
  openstack-neutron-ml2 
  python-neutronclient
  python-keystoneclient
  ].each do |pkg|
  package pkg do
    action :install
  end
end

%w[
  neutron-openvswitch-agent
  neutron-ovs-cleanup
].each do |srv| 
  service srv do
    action :enable
  end
end

service "openvswitch" do
    action [:enable, :start]
end 

execute 'set openvswitch local_ip' do
  command %Q[ovs-vsctl set Open_vSwitch ]<<
    %Q[$(ovs-vsctl get Open_vSwitch . _uuid) ]<<
    %Q[other_config={'local_ip'='#{node[:auto][:internal_ip]}'}]
  action :run
end

execute 'set openvswitch manager' do
  command "ovs-vsctl set-manager tcp:#{node[:ip][:neutron]}:6640"
  action :run
end
  
link "/etc/neutron/plugin.ini" do
  to "/etc/neutron/plugins/ml2/ml2_conf.ini"
  link_type :symbolic
end

uuid = Mixlib::ShellOut.new(%Q[/usr/bin/keystone ]<<
  %Q[--os-token #{node[:creds][:keystone_token]} ]<<
  %Q[--os-endpoint http://#{node[:ip][:keystone]}:35357/v2.0 ]<<
  %Q[tenant-list | grep admin | awk '{print $2}'])
uuid.run_command
uuid.error!
admin_id  = uuid.stdout[0..-2]

template "/etc/neutron/plugins/ml2/ml2_conf.ini" do
  mode "0640"
  owner "root"
  group "neutron"
  source "neutron/ml2_conf.ini.erb"  
  notifies :restart, "service[neutron-openvswitch-agent]"
end

template "/etc/neutron/neutron.conf" do
  mode "0640"
  owner "root"
  group "neutron"
  source "neutron/neutron.conf.erb"
  variables({
    :tenant_id => admin_id
  })
  notifies :restart, "service[neutron-openvswitch-agent]"
end

firewalld_rule "nova-compute" do
  action :set
  protocol "tcp"
  port %w[9696]
end

