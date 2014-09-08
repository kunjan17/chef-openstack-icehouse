#
# Cookbook Name:: centos-cloud
# Recipe:: neutron
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
require "socket"

include_recipe "libcloud"
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::mysql"
include_recipe "centos_cloud::opendaylight"
include_recipe "centos_cloud::openvswitch"
include_recipe "centos_cloud::iptables-policy"

libcloud_ssh_keys node[:creds][:ssh_keypair] do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

centos_cloud_database "neutron" do
  password node[:creds][:mysql_password]
end

#execute "ovs-vsctl add-br br-ex" do
#  not_if("ovs-vsctl list-br | grep br-ex")
#  action :run
#end

template "/etc/sysconfig/network-scripts/ifcfg-" + node[:auto][:external_nic]  do
  not_if do
    File.exists?("/etc/sysconfig/network-scripts/ifcfg-br-ex")
  end
  owner "root"
  group "root"
  mode  "0644"
  source "neutron/ifcfg-ethX.erb"
end

template "/etc/sysconfig/network-scripts/ifcfg-br-ex" do
  not_if do
    File.exists?("/etc/sysconfig/network-scripts/ifcfg-br-ex")
  end
  owner "root"
  group "root"
  mode  "0644"
  source "neutron/ifcfg-br-ex.erb"
end

service "network" do
  action :restart
end

centos_cloud_config "/etc/neutron/metadata_agent.ini" do
  command ["DEFAULT auth_strategy keystone",
    "DEFAULT auth_url http://#{node[:ip][:keystone]}:35357/v2.0",
    "DEFAULT admin_tenant_name admin",
    "DEFAULT admin_user admin",
    "DEFAULT admin_password #{node[:creds][:admin_password]}",
    "DEFAULT metadata_proxy_shared_secret #{node[:creds][:neutron_secret]}",
    "DEFAULT nova_metadata_ip #{node[:ip][:nova]}"]
end

centos_cloud_config "/etc/neutron/dhcp_agent.ini" do
  command ["DEFAULT enable_isolated_metadata True",
    "DEFAULT use_namespaces True",
    "DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver",
    "DEFAULT dnsmasq_dns_server 8.8.8.8",
    "DEFAULT ovs_use_veth True",
    "DEFAULT dnsmasq_config_file /etc/neutron/dnsmasq-neutron.conf"]
end

centos_cloud_config "/etc/neutron/lbaas_agent.ini" do
  command ["DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver",
    "DEFAULT device_driver neutron.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver",
    "haproxy user_group haproxy"]
end

libcloud_file_append "/etc/neutron/dnsmasq-neutron.conf" do
  line ["dhcp-option-force=26,1454"]
end

centos_cloud_config "/etc/neutron/l3_agent.ini" do
  command ["DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver",
    "DEFAULT external_network_bridge br-ex",
    "DEFAULT use_namespaces True",
    "DEFAULT ovs_use_veth True"]
end

#Support for configurating neutron
template "/root/floating-pool.sh" do
  source "neutron/floating-pool.erb"
  owner "root"
  group "root"
  mode "0744"
end

%w[openvswitch neutron-dhcp-agent neutron-openvswitch-agent neutron-l3-agent neutron-server neutron-metadata-agent].each do |srv|
  service srv do
    action [:enable, :restart]
  end
end
