require "socket"
require 'securerandom'

def my_first_private_ipv4
  Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
end

def my_first_public_ipv4
  Socket.ip_address_list.detect{|intf| intf.ipv4? \
                                  and !intf.ipv4_loopback? \
                                  and !intf.ipv4_multicast? \
                                  and !intf.ipv4_private?}
end

external_ipv4 = my_first_public_ipv4.nil? ? my_first_private_ipv4.ip_address : my_first_public_ipv4.ip_address
internal_ipv4 = my_first_private_ipv4.nil? ? my_first_public_ipv4.ip_address : my_first_private_ipv4.ip_address

iface = Mixlib::ShellOut.new("ip a | awk '/#{external_ipv4}/ { print $7 }'")
iface.run_command
iface.error!
external_iface = iface.stdout[0..-2]

vg = Mixlib::ShellOut.new("vgs --sort -size --rows | grep VG -m 1 | awk '{print $2}'")
vg.run_command
vg.error!
largest_vg  = vg.stdout[0..-2]

default[:auto][:volume_group] = largest_vg
default[:auto][:external_ip]  = external_ipv4
default[:auto][:internal_ip]  = internal_ipv4
default[:auto][:external_nic] = external_iface
default[:auto][:gateway] = node[:network][:default_gateway]
default[:auto][:netmask] = node[:network][:interfaces][external_iface]\
[:addresses][external_ipv4][:netmask]

#default[:creds][:admin_password]  = SecureRandom.urlsafe_base64(8)
#default[:creds][:mysql_password]  = SecureRandom.urlsafe_base64(8)
default[:creds][:admin_password]  = "cl0udAdmin"
default[:creds][:mysql_password]  = "cl0udAdmin"
default[:creds][:rabbitmq_password] = "cl0udAdmin"
#default[:creds][:keystone_token]  = SecureRandom.urlsafe_base64(20)
#default[:creds][:swift_hash]      = SecureRandom.urlsafe_base64(20)
#default[:creds][:neutron_secret]  = SecureRandom.urlsafe_base64(20)
default[:creds][:keystone_token]  = "Key5t0ne5ecret"
default[:creds][:swift_hash]      = "5wift5ecret"
default[:creds][:neutron_secret]  = "Neutr0n5ecret"
default[:creds][:metering_secret] = "Metering5ecret"
default[:creds][:ssh_keypair]     = "openstack"
default[:creds][:esxi_password]   = "mySuperSecret"

default[:ip][:controller]     = node[:auto][:internal_ip]
default[:ip_ex][:controller]  = node[:auto][:external_ip]
#default[:ip][:qpid]           = node[:ip][:controller]
default[:ip][:rabbitmq]       = node[:ip][:controller]
default[:ip][:keystone]       = node[:ip][:controller]
default[:ip_ex][:keystone]    = node[:ip_ex][:controller]
default[:ip][:swift]          = node[:ip][:controller]
default[:ip_ex][:swift]       = node[:ip_ex][:controller] 
default[:ip][:glance]         = node[:ip][:controller]
default[:ip_ex][:glance]      = node[:ip_ex][:controller]
default[:ip][:cinder]         = node[:ip][:controller]
default[:ip_ex][:cinder]      = node[:ip_ex][:controller]  
default[:ip][:neutron]        = node[:ip][:controller]
default[:ip_ex][:neutron]     = node[:ip_ex][:controller] 
default[:ip][:nova]           = node[:ip][:controller]
default[:ip_ex][:nova]        = node[:ip_ex][:controller] 
default[:ip][:heat]           = node[:ip][:controller]
default[:ip_ex][:heat]        = node[:ip_ex][:controller] 
default[:ip][:ceilometer]     = node[:ip][:controller]
default[:ip_ex][:ceilometer]  = node[:ip_ex][:controller]
default[:ip][:sahara]         = node[:ip][:controller]
default[:ip_ex][:sahara]      = node[:ip_ex][:controller]
default[:ip][:monitoring]     = node[:ip][:controller]
  
default[:ip][:esxi]                   = "192.168.250.100"
default[:ip][:nexenta]                = "195.208.117.178"
  

