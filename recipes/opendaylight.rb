include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::iptables-policy"
include_recipe "libcloud"

simple_iptables_rule "opendaylight" do
  rule "-p tcp -m multiport --dports 8383,33343,12001,60601,6633,47914,7800,6633,8081"
  jump "ACCEPT"
end

package "opendaylight" do
  action :install
end

template "/usr/share/opendaylight-controller/configuration/tomcat-server.xml" do
  owner "root"
  group "root"
  mode  "0644"
  source "opendaylight/tomcat-server.xml.erb"
end

template "/etc/sysconfig/opendaylight-controller" do
  owner "root"
  group "root"
  mode  "0644"
  source "opendaylight/opendaylight-controller.erb"
end

execute 'ovs-vsctl set Open_vSwitch $(ovs-vsctl get Open_vSwitch . _uuid) other_config={"local_ip"=#{node[:auto][:internal_ip]}}'

execute "rm -f /var/lib/opendaylight-controller/plugins/org.opendaylight.controller.samples.simpleforwarding-*" do
  action :run
  ignore_failure true
end

service "opendaylight-controller" do
  action [:enable, :restart]
end

