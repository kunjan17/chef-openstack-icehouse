include_recipe "centos_cloud::repos"

%w[centos-release bash-completion].each do |pkg|
  package pkg do
    action :install
  end
end