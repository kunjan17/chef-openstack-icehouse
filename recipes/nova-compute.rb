#
# Cookbook Name:: centos-cloud
# Recipe:: nova-compute
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#

include_recipe "libcloud"
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::openvswitch"
include_recipe "centos_cloud::iptables-policy"

%w[openstack-nova-compute openstack-ceilometer-compute].each do |pkg|
  package pkg do
    action :install
  end
end

simple_iptables_rule "novnc" do
  rule "-p tcp -m multiport --dports 5900:5999,6080,6081,6082"
  jump "ACCEPT"
end

libcloud_ssh_keys node[:creds][:ssh_keypair] do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

centos_cloud_config "/etc/nova/nova.conf" do
  command [
    "DEFAULT sql_connection" <<
    " mysql://nova:#{node[:creds][:mysql_password]}@#{node[:ip][:nova]}/nova",
#    "DEFAULT rpc_backend nova.openstack.common.rpc.impl_qpid",
#    "DEFAULT qpid_hostname #{node[:ip][:qpid]}",
    "DEFAULT rpc_backend nova.openstack.common.rpc.impl_kombu",
    "DEFAULT rabbit_host #{node[:ip][:rabbitmq]}",
    "DEFAULT rabbit_password #{node[:creds][:rabbitmq_password]}",
    "DEFAULT network_api_class nova.network.neutronv2.api.API",
    "DEFAULT neutron_auth_strategy keystone",
    "DEFAULT neutron_url http://#{node[:ip][:neutron]}:9696/",
    "DEFAULT neutron_admin_tenant_name admin",
    "DEFAULT neutron_admin_username admin",
    "DEFAULT neutron_admin_password #{node[:creds][:admin_password]}",
    "DEFAULT neutron_admin_auth_url" <<
    " http://#{node[:ip][:neutron]}:35357/v2.0",
    "DEFAULT security_group_api neutron",
    "DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver",
    "DEFAULT libvirt_vif_driver" <<
    " nova.virt.libvirt.vif.LibvirtGenericVIFDriver",
    "DEFAULT auth_strategy keystone",
    "DEFAULT vnc_enabled true",
    "DEFAULT allow_admin_api true",
    "DEFAULT use_deprecated_auth false",
    "DEFAULT dmz_cidr 169.254.169.254/32",
    "DEFAULT metadata_host #{node[:auto][:internal_ip]}",
    "DEFAULT metadata_listen 0.0.0.0",
    "DEFAULT enabled_apis ec2,osapi_compute,metadata",
    "DEFAULT novncproxy_base_url" <<
    " http://#{node[:ip_ex][:nova]}:6080/vnc_auto.html",
    "DEFAULT vncserver_proxyclient_address #{node[:auto][:internal_ip]}",
    "DEFAULT vncserver_listen #{node[:auto][:internal_ip]}",
    "DEFAULT resume_guests_state_on_host_boot true",
    "DEFAULT service_neutron_metadata_proxy True",
    "DEFAULT instance_usage_audit True",
    "DEFAULT instance_usage_audit_period hour",
    "DEFAULT notify_on_state_change vm_and_task_state",
    "DEFAULT notification_driver nova.openstack.common.notifier.rpc_notifier",
    "DEFAULT notification_driver ceilometer.compute.nova_notifier",
    "DEFAULT neutron_metadata_proxy_shared_secret" <<
    " #{node[:creds][:neutron_secret]}",
    "DEFAULT libvirt_type qemu",
    "DEFAULT glance_api_servers #{node[:ip][:glance]}:9292",
    "spice agent_enabled True",
    "spice enabled True",
    "spice html5proxy_base_url" <<
    " http://#{node[:ip][:nova]}:6082/spice_auto.html",
    "spice keymap en-us",
    "spice server_listen 127.0.0.1",
    "spice server_proxyclient_address 127.0.0.1",
    "DEFAULT vif_plugging_is_fatal false",
    "DEFAULT vif_plugging_timeout 0",
    "keystone_authtoken admin_tenant_name admin",
    "keystone_authtoken admin_user admin",
    "keystone_authtoken admin_password #{node[:creds][:admin_password]}",
    "keystone_authtoken auth_host #{node[:ip][:keystone]}",
    "keystone_authtoken identity_uri http://#{node[:ip][:keystone]}:35357"
  ]
end

centos_cloud_config "/etc/ceilometer/ceilometer.conf" do
  command ["DEFAULT rpc_backend nova.openstack.common.rpc.impl_qpid",
    "DEFAULT log_dir /var/log/ceilometer",
    "DEFAULT qpid_hostname #{node[:ip][:qpid]}",
    "database connection mysql://ceilometer:#{node[:creds][:mysql_password]}@localhost/ceilometer",
    "publisher_rpc metering_secret #{node[:creds][:metering_secret]}",
    "keystone_authtoken service_host #{node[:ip][:keystone]}",
    "keystone_authtoken auth_host #{node[:ip][:keystone]}",
    "keystone_authtoken auth_uri http://#{node[:ip][:keystone]}:35357/v2.0",
    "keystone_authtoken admin_tenant_name admin",
    "keystone_authtoken admin_user admin",
    "keystone_authtoken auth_port 35357",
    "keystone_authtoken auth_protocol http",
    "keystone_authtoken admin_password #{node[:creds][:admin_password]}",
    "service_credentials os_password #{node[:creds][:admin_password]}",
    "service_credentials os_auth_url http://#{node[:ip][:keystone]}:35357/v2.0",
    "service_credentials os_username admin",
    "service_credentials os_tenant_name admin"
  ]
end

#%w[libvirtd messagebus openstack-nova-compute
%w[libvirtd openstack-nova-compute
openstack-ceilometer-compute
].each do |srv|
  service srv do
    action [:enable,:restart]
  end
end

execute "virsh net-destroy default" do
  only_if("virsh net-list | grep default")
  action :run
end

execute "virsh net-undefine default" do
  only_if("virsh net-list --all| grep default")
  action :run
end

#service "openstack-nova-metadata-api" do
#    not_if do
#        node[:ipaddress] == node[:ip][:nova]
#    end
#    action [:enable,:restart]
#end
