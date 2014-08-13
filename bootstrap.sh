#!/bin/bash
if [[ $EUID -ne 0 ]]; then
echo "You must be a root user" 2>&1
exit 1
fi
rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uvh http://rbel.co/rbel6
yum -y install ruby19 ruby-devel rubygems git openssh-clients rubygem-mime-types make gcc
gem install --no-rdoc --no-ri chef 
gem install --no-rdoc --no-ri knife-solo
gem install --no-rdoc --no-ri knife-solo_data_bag json
knife configure --defaults -y -r .defaults
knife solo init ~/pilgrim
if [ ! -f ~/.ssh/id_rsa ]
then
ssh-keygen -q -t rsa -f ~/.ssh/cloud_key -N ""
fi
if [ ! -f ~/.ssh/id_rsa ]
then
ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ""
fi
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
knife solo data bag create ssh_keypairs openstack --json "$(ruby19 -rjson -e 'puts JSON.generate({"id"=>"openstack","private_key" => File.read("/root/.ssh/cloud_key"), "public_key" => File.read("/root/.ssh/cloud_key.pub")})')" --data-bag-path ~/pilgrim/data_bags
git clone https://github.com/laboshinl/openstack-havana-cookbook.git ~/pilgrim/cookbooks/centos_cloud
git clone https://github.com/laboshinl/libcloud.git ~/pilgrim/cookbooks/libcloud
git clone https://github.com/laboshinl/simple_iptables.git ~/pilgrim/cookbooks/simple_iptables
git clone https://github.com/laboshinl/selinux.git ~/pilgrim/cookbooks/selinux
git clone https://github.com/laboshinl/tar.git ~/pilgrim/cookbooks/tar
cd ~/pilgrim
echo '{"run_list":["recipe[centos_cloud]"]}' > nodes/localhost.json
knife solo bootstrap localhost
