#
# Cookbook Name:: centos-cloud
# Recipe:: openvswitch
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::iptables-policy"
include_recipe "libcloud"

package "openstack-neutron-openvswitch" do
  action :install
end

package "bridge-utils" do
  action :install
end

service "openvswitch" do
  action [:enable, :restart]
end

link "/etc/neutron/plugin.ini" do
  to "/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini"
  link_type :symbolic
end

centos_cloud_config "/etc/neutron/plugin.ini" do
  command ["DATABASE sql_connection mysql://neutron:#{node[:creds][:mysql_password]}@#{node[:ip][:neutron]}/neutron",
    "SECURITYGROUP firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver",
    "OVS tenant_network_type vlan",
    "OVS network_vlan_ranges default:2000:3999",
    "OVS integration_bridge br-int",
    "OVS bridge_mappings default:br-ex"]
end

centos_cloud_config "/etc/neutron/neutron.conf" do
  command ["DEFAULT auth_strategy keystone",
    "DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid",
    "DEFAULT qpid_hostname #{node[:ip][:qpid]}",
    "DEFAULT allow_overlapping_ips True",
    "DEFAULT core_plugin neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2",
    "agent root_helper 'sudo neutron-rootwrap /etc/neutron/rootwrap.conf'",
    "keystone_authtoken auth_host #{node[:ip][:keystone]}",
    "keystone_authtoken admin_tenant_name admin",
    "keystone_authtoken admin_user admin",
    "keystone_authtoken admin_password #{node[:creds][:admin_password]}"]
end

%w[iproute kernel].each do |pkg|
  package pkg do
    action :upgrade
  end
end

template "/etc/sysconfig/network-scripts/ifcfg-" + node[:auto][:external_nic]  do
  not_if do
    File.exists?("/etc/sysconfig/network-scripts/ifcfg-br-ex")
  end
  owner "root"
  group "root"
  mode  "0644"
  source "neutron/ifcfg-eth0.erb"
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

libcloud_file_append "/etc/sysconfig/network-scripts/ifcfg-br-int" do
  line ["DEVICE=br-int",
    "DEVICETYPE=ovs",
    "TYPE=OVSBridge",
    "ONBOOT=yes",
    "BOOTPROTO=none"]
end

service "network" do
  action :restart
end

simple_iptables_rule "neutron" do
  rule "-p tcp -m multiport --dports 9696"
  jump "ACCEPT"
end

%w[neutron-openvswitch-agent neutron-ovs-cleanup].each do |srv|
  service srv do
    action [:enable, :restart]
  end
end

