action :add do
  keypair = data_bag_item(new_resource.databag, new_resource.item)

  keypair["private_key"]
  keypair["public_key"]

  package "openssh-clients" do
    action :install
  end

  #add openstack.pub to known hosts
  execute "echo #{keypair["public_key"]} >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys" do
    not_if("grep #{keypair["public_key"]} /root/.ssh/authorized_keys")
  end
  execute "echo #{keypair["private_key"]} >> /root/.ssh/#{new_resource.item} && chmod 600 /root/.ssh/#{new_resource.item}"
  new_resource.updated_by_last_action(true)
end