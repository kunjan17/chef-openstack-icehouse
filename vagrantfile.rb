homebase = "/home/laboshinl/vagrant"
require 'chef'

Chef::Config.from_file(File.join('/home/laboshinl/.chef', 'knife.rb'))
Vagrant::Config.run do |config|
  config.vm.box = "centos-6.4-x86_64"
  config.vm.box_url = "http://developer.nrel.gov/downloads/vagrant-boxes/CentOS-6.4-x86_64-v20130731.box"
  config.vm.network :hostonly, "10.111.222.33"
  config.vm.customize ["modifyvm", :id, "--memory", 2048]
  config.vm.provision :chef_client do |chef|
    chef.chef_server_url = Chef::Config[:chef_server_url]
    chef.log_level = Chef::Config[:log_level]
    chef.node_name = 'vagrant'
    chef.validation_key_path = Chef::Config[:validation_key]
    chef.validation_client_name = Chef::Config[:validation_client_name]
    chef.add_recipe "centos_cloud::keystone"
  end
end