include_recipe "libcloud"
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::iptables-policy"

libcloud_ssh_keys node[:creds][:ssh_keypair] do
  data_bag "ssh_keypairs"
  action [:create, :add]
end

%w[ nagios nagios-plugins-all nagios-plugins-nrpe nrpe
ganglia ganglia-gmond].each do |pkg|
  package pkg do
    action :install
  end
end

simple_iptables_rule "nagios" do
  rule "-p tcp -m multiport --dports 5666"
  jump "ACCEPT"
end

template "/etc/ganglia/gmond.conf" do
  source "monitoring/gmond.conf.erb"
  owner "root"
  group "root"
  mode "0644"
end

template "/tmp/newhost.cfg" do
  source "monitoring/newhost.cfg.erb"
  owner "root"
  group "root"
  mode "0644"
end

libcloud_file_scp "/tmp/newhost.cfg" do
  action :upload
  server node[:ip][:monitoring]
  remote_path "/etc/nagios/conf.d/host-#{node[:auto][:external_ip]}.cfg"
end

libcloud_ssh_command "service nagios start" do
  server node[:ip][:monitoring]
end

libcloud_ssh_command "service nagios restart" do
  server node[:ip][:monitoring]
end

%w[nagios gmond nrpe].each do |srv|
  service srv do
    action [:start, :enable, :restart]
  end
end