include_recipe "selinux::disabled"
include_recipe "centos_cloud::repos"
include_recipe "centos_cloud::iptables-policy"
include_recipe "libcloud"

#Add firewall rules 
#NEED FIX! remove unnecessary ports
simple_iptables_rule "opendaylight" do
  rule "-p tcp -m multiport --dports 6640,8383,33343,12001,60601,6633,47914,7800,6633,8081"
  jump "ACCEPT"
end

#Install necessary packages (unzip, java, etc.)
%w[unzip opendaylight-controller-dependencies].each do |pkg|
  package pkg do
    action :install
  end
end

#Download zip file 
remote_file "/tmp/distributions-virtualization-0.1.1-osgipackage.zip" do
  source "http://xenlet.stu.neva.ru/distributions-virtualization-0.1.1-osgipackage.zip",
         "https://nexus.opendaylight.org/content/repositories/opendaylight.release/org/opendaylight/integration/distributions-virtualization/0.1.1/distributions-virtualization-0.1.1-osgipackage.zip"
  owner 'root'
  group 'root'
  mode "0644"
end

#Extract zip file
bash 'extract_odl' do
  cwd "/usr/share"
  code <<-EOH
      unzip /tmp/distributions-virtualization-0.1.1-osgipackage.zip
    EOH
  not_if { ::File.exists?("/usr/share/opendaylight") }
end

#Change WebUI port to 8081
template "/usr/share/opendaylight/configuration/tomcat-server.xml" do
  owner "root"
  group "root"
  mode  "0644"
  source "opendaylight/tomcat-server.xml.erb"
end

# Init script
template "/usr/lib/systemd/system/opendaylight-controller.service" do
  owner "root"
  group "root"
  mode  "0644"
  source "opendaylight/opendaylight-controller.service.erb"
end

# Disable Simple forwarding
execute "rm -f /usr/share/opendaylight/plugins/org.opendaylight.controller.samples.simpleforwarding-*" do
  action :run
  ignore_failure true
end

service "opendaylight-controller" do
  action [:enable, :restart]
end
