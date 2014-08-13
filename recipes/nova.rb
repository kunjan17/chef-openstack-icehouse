#
# Cookbook Name:: centos-cloud
# Recipe:: nova
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "tar"
include_recipe "libcloud"
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::mysql"
include_recipe "centos_cloud::iptables-policy"

%w[
mod_wsgi httpd mod_ssl openstack-dashboard
memcached python-memcached
].each do |pkg|
  package pkg do
    action :install
  end
end

simple_iptables_rule "dashboard" do
  rule "-p tcp -m multiport --dports 80,443"
  jump "ACCEPT"
end

#BugFix
execute "sed -i 's/DEBUG = False/DEBUG = True/' /etc/openstack-dashboard/local_settings" do
  action :run
end

libcloud_ssh_keys node[:creds][:ssh_keypair] do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

centos_cloud_database "nova" do
  password node[:creds][:mysql_password]
end

%w[openstack-nova-api openstack-nova-scheduler
openstack-nova-conductor openstack-nova-console
openstack-nova-cert openstack-nova-novncproxy
].each do |pkg|
  package pkg do
    action :install
  end
end

#centos_cloud_config "/etc/nova/api-paste.ini" do
#    command "filter:authtoken signing_dir /var/lib/nova/keystone-signing"
#end

centos_cloud_config "/etc/nova/nova.conf" do
  command [
    "DEFAULT sql_connection" <<
    " mysql://nova:#{node[:creds][:mysql_password]}@localhost/nova",
    "DEFAULT rpc_backend nova.openstack.common.rpc.impl_qpid",
    "DEFAULT qpid_hostname #{node[:ip][:qpid]}",
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
    "DEFAULT allow_admin_api true",
    "DEFAULT use_deprecated_auth false",
    "DEFAULT dmz_cidr 169.254.169.254/32",
    "DEFAULT metadata_host #{node[:ipaddress]}",
    "DEFAULT metadata_listen 0.0.0.0",
    "DEFAULT enabled_apis ec2,osapi_compute,metadata",
    "DEFAULT novncproxy_base_url" <<
    " http://#{node[:auto][:external_ip]}:6080/vnc_auto.html",
    "DEFAULT vnc_enabled True",
    "DEFAULT vncserver_proxyclient_address #{node[:auto][:interanal_ip]}",
    "DEFAULT vncserver_listen 0.0.0.0",
    "spice enabled True",
    "spice html5proxy_base_url" <<
    " http://#{node[:ipaddress]}:6082/spice_auto.html",
    "spice keymap en-us",
    "DEFAULT resume_guests_state_on_host_boot true",
    "DEFAULT service_neutron_metadata_proxy True",
    "DEFAULT neutron_metadata_proxy_shared_secret" <<
    " #{node[:creds][:neutron_secret]}",
    "DEFAULT glance_api_servers #{node[:ip][:glance]}:9292",
    "keystone_authtoken admin_tenant_name admin",
    "keystone_authtoken admin_user admin",
    "keystone_authtoken admin_password #{node[:creds][:admin_password]}",
    "keystone_authtoken auth_host #{node[:ip][:keystone]}"
  ]
end

simple_iptables_rule "novnc" do
  rule "-m state --state NEW -m tcp -p tcp --dport 6082"
  jump "ACCEPT"
end

simple_iptables_rule "nova" do
  rule "-p tcp -m multiport --dports 8773,8774,8775"
  jump "ACCEPT"
end

execute "su nova -s /bin/sh -c 'nova-manage db sync'" do
  action :run
end

tar_extract "http://xenlet.stu.neva.ru/spice/spice-html5.tar.gz" do
  target_dir "/usr/share/"
end

template "/etc/httpd/conf.d/spice.conf" do
  owner "root"
  group "root"
  mode  "0644"
  source "spice.conf.erb"
end

cookbook_file "/usr/share/openstack-dashboard/static/dashboard/img/logo.png" do
  source "logo.png"
  mode "0755"
  owner "root"
  group "root"
end

cookbook_file "/usr/share/openstack-dashboard/static/dashboard/img/logo-splash.png" do
  source "logo.png"
  mode "0755"
  owner "root"
  group "root"
end

%w[
openstack-nova-spicehtml5proxy openstack-nova-api
openstack-nova-scheduler openstack-nova-conductor
openstack-nova-console openstack-nova-consoleauth
openstack-nova-cert openstack-nova-novncproxy
httpd
].each do |srv|
  service srv do
    action [:enable, :restart]
  end
end

