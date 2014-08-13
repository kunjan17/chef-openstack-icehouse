action :set do
  if new_resource.command.kind_of?(String)
    commands = [new_resource.command]
  else
    commands = new_resource.command
  end
  package "openstack-utils"
  commands.each do |command|
    execute "openstack-config --set #{new_resource.file} #{command}"
  end
  new_resource.updated_by_last_action(true)
end
