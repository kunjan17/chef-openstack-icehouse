action :create do
  bash "create new_resource.name database" do
    code <<-CODE
mysql -uroot -p#{new_resource.password} << EOF
CREATE DATABASE IF NOT EXISTS #{new_resource.name};
GRANT ALL PRIVILEGES ON #{new_resource.name}.* 
TO '#{new_resource.name}'@'%' 
IDENTIFIED BY '#{new_resource.password}';
GRANT ALL PRIVILEGES ON #{new_resource.name}.* 
TO '#{new_resource.name}'@'localhost' 
IDENTIFIED BY '#{new_resource.password}';
GRANT ALL PRIVILEGES ON #{new_resource.name}.* 
TO '#{new_resource.name}'@#{node[:fqdn]} 
IDENTIFIED BY '#{new_resource.password}';
EOF
    CODE
  end
  new_resource.updated_by_last_action(true)
end
