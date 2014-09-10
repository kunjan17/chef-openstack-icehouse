include_recipe "centos_cloud::selinux"
include_recipe "centos_cloud::repos"
include_recipe "firewalld"
include_recipe "libcloud::ssh_key"

#Add firewall rules 
firewalld_rule "dashboard" do
  action :set
  protocol "tcp"
  port %w[6640 6633 8081]
end

%w[
  unzip
  java-1.7.0-openjdk
].each do |pkg|
  package pkg do
    action :install
  end
end

#Download zip file 
remote_file "#{Chef::Config[:file_cache_path]}"<<
              "/distributions-virtualization-0.1.1-osgipackage.zip" do
  source "http://xenlet.stu.neva.ru"<<
           "/distributions-virtualization-0.1.1-osgipackage.zip",
         "https://nexus.opendaylight.org/content/repositories"<<
           "/opendaylight.release/org/opendaylight/integration"<<
           "/distributions-virtualization/0.1.1"<<
	   "/distributions-virtualization-0.1.1-osgipackage.zip"
  owner 'root'
  group 'root'
  mode "0644"
end

#Extract zip file
bash 'extract_odl' do
  cwd "/usr/share"
  code "unzip #{Chef::Config[:file_cache_path]}/"<<
       "distributions-virtualization-0.1.1-osgipackage.zip"
  not_if { ::File.exists?("/usr/share/opendaylight") }
end

# Init script
template "/usr/lib/systemd/system/opendaylight-controller.service" do
  owner "root"
  group "root"
  mode  "0644"
  source "opendaylight/opendaylight-controller.service.erb"
end

service "opendaylight-controller" do
  action [:enable]
end

#Change WebUI port to 8081
template "/usr/share/opendaylight/configuration/tomcat-server.xml" do
  owner "root"
  group "root"
  mode  "0644"
  source "opendaylight/tomcat-server.xml.erb"
  notifies :restart, "service[opendaylight-controller]"
end

# Disable Simple forwarding
execute "rm -f /usr/share/opendaylight/plugins/"<<
          "org.opendaylight.controller.samples.simpleforwarding-*" do
  action :run
  ignore_failure true
end

