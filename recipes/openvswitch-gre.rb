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

%w[openstack-neutron-openvswitch openstack-neutron-ml2 python-neutronclient].each do |pkg|
  package pkg do
    action :install
  end
end

package "bridge-utils" do
  action :install
end

service "openvswitch" do
  action [:enable, :restart]
end

#link "/etc/neutron/plugin.ini" do
#  to "/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini"
#  link_type :symbolic
#end

link "/etc/neutron/plugin.ini" do
  to "/etc/neutron/plugins/ml2/ml2_conf.ini"
  link_type :symbolic
end

uuid = Mixlib::ShellOut.new("keystone --os-token #{node[:creds][:keystone_token]} --os-endpoint #{'http://' + node[:ip][:keystone] + ':35357/v2.0'} tenant-list | grep admin | awk '{print $2}'")
uuid.run_command
uuid.error!
admin_id  = uuid.stdout[0..-2]

#centos_cloud_config "/etc/neutron/plugin.ini" do
#  command ["DATABASE sql_connection mysql://neutron:#{node[:creds][:mysql_password]}@#{node[:ip][:neutron]}/neutron",
#    "SECURITYGROUP firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver",
#    "OVS enable_tunneling True",
#    "OVS tenant_network_type gre",
#    "OVS integration_bridge br-int",
#    "OVS tunnel_bridge br-tun",
#    "OVS tunnel_id_ranges 1:1000",
#    "OVS local_ip #{node[:auto][:internal_ip]}"]
#end

centos_cloud_config "/etc/neutron/plugin.ini" do
  command ["securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver",
    "securitygroup enable_security_group True",
    "ml2 tenant_network_types gre",
    "ml2 type_drivers gre",
    "ml2 mechanism_drivers opendaylight",
    "ml2_type_gre tunnel_id_ranges 1:1000",
    "ovs enable_tunneling True",
    #    "OVS tenant_network_type gre",
    "odl integration_bridge br-int",
    "odl tunnel_bridge br-tun",
    "odl controllers #{node[:ip][:neutron]}:8081:admin:admin",
    "odl tunnel_id_ranges 1:1000",
    "odl tun_peer_patch_port patch-int",
    "odl int_peer_patch_port patch-tun",
    #    "OVS tunnel_id_ranges 1:1000",
    "ovs local_ip #{node[:auto][:internal_ip]}",
    "agent minimize_polling True",
    "ml2_odl password admin",
    "ml2_odl username admin",
    "ml2_odl url http://#{node[:ip][:neutron]}:8081/controller/nb/v2/neutron"]
end

centos_cloud_config "/etc/neutron/neutron.conf" do
  command ["DEFAULT auth_strategy keystone",
    "DEFAULT rpc_backend neutron.openstack.common.rpc.impl_qpid",
    "DEFAULT qpid_hostname #{node[:ip][:qpid]}",
    "DEFAULT allow_overlapping_ips True",
#    "DEFAULT core_plugin neutron.plugins.openvswitch.ovs_neutron_plugin.OVSNeutronPluginV2",
    "DEFAULT core_plugin ml2",
    "DEFAULT service_plugins router",
    "keystone_authtoken auth_host #{node[:ip][:keystone]}",
    "keystone_authtoken admin_tenant_name admin",
    "keystone_authtoken admin_user admin",
    "keystone_authtoken admin_password #{node[:creds][:admin_password]}",
    "DEFAULT notify_nova_on_port_status_changes True",
    "DEFAULT notify_nova_on_port_data_changes True",
    "DEFAULT nova_url http://#{node[:ip][:nova]}:8774/v2",
    "DEFAULT nova_admin_username admin",
    "DEFAULT nova_admin_tenant_id #{admin_id}",
    "DEFAULT nova_admin_password #{node[:creds][:admin_password]}",
    "DEFAULT nova_admin_auth_url http://#{node[:ip][:keystone]}:35357/v2.0",
    "database connection mysql://neutron:#{node[:creds][:mysql_password]}@#{node[:ip][:neutron]}/neutron"]
end

%w[iproute kernel].each do |pkg|
  package pkg do
    action :upgrade
  end
end

%w[openvswitch neutron-openvswitch-agent neutron-ovs-cleanup].each do |srv|
  service srv do
    action [:enable, :restart]
  end
end

execute "ovs-vsctl add-br br-int" do
  not_if("ovs-vsctl list-br | grep br-int")
  action :run
end

simple_iptables_rule "neutron" do
  rule "-p tcp -m multiport --dports 9696"
  jump "ACCEPT"
end

libcloud_file_append "/etc/sysconfig/network-scripts/ifcfg-br-int" do
  line ["DEVICE=br-int",
    "DEVICETYPE=ovs",
    "TYPE=OVSBridge",
    "ONBOOT=yes",
    "BOOTPROTO=none"]
end

