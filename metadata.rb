name             'centos_cloud'
maintainer       'cloudtechlab'
maintainer_email 'laboshinl@gmail.com'
license          'Do What The Fuck You Want To Public License, Version 2'
description      'Installs/Configures openstack cloudstructure based on CentOS 7.0'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.10.0'
%w{firewalld libcloud tar lvm}.each do |depend|
  depends depend
end
supports "centos", ">= 7.0"
