include_recipe "libcloud"
include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::iptables-policy"

%w[expect nagios php httpd
ganglia ganglia-gmetad ganglia-web].each do |pkg|
  package pkg do
    action :install
  end
end

simple_iptables_rule "monitoring-server" do
  rule "-p tcp -m multiport --dports 80,25,8652,8651,8649,111,8655"
  jump "ACCEPT"
end

simple_iptables_rule "monitoring-server" do
  rule "-p udp -m multiport --dports 8649"
  jump "ACCEPT"
end


template "/tmp/expect" do
  source "monitoring/expect.erb"
  owner "root"
  group "root"
  mode "0700"
end

execute "/tmp/expect" do
  action :run
end

template "/etc/httpd/conf.d/ganglia.conf" do
  source "monitoring/ganglia.conf.erb"
  owner "root"
  group "root"
  mode "0644"
end

%w[httpd nagios gmetad].each do |srv|
  service srv do
    action [:start, :enable, :restart]
  end
end

