include_recipe "centos_cloud::repos"

package "bash-completion" do
  action :install
end