template "/root/test.sh" do
  source "test.sh.erb"
  owner "root"
  group "root"
  mode "0755"
end

execute "bash /root/floating-pool.sh"
execute "bash /root/test.sh"
