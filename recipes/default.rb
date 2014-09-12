#
# Cookbook Name:: centos_cloud
# Recipe:: default
#
# Copyright © 2014 Leonid Laboshin <laboshinl@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See http://www.wtfpl.net/ for more details.

include_recipe "centos_cloud::ntp-server"
include_recipe "centos_cloud::rabbitmq-server"
#core
include_recipe "centos_cloud::keystone"
include_recipe "centos_cloud::glance"
include_recipe "centos_cloud::cinder"
include_recipe "centos_cloud::nova"
include_recipe "centos_cloud::neutron"
#misc
include_recipe "centos_cloud::swift-proxy"
include_recipe "centos_cloud::heat"
include_recipe "centos_cloud::ceilometer"
include_recipe "centos_cloud::sahara"
#compute
include_recipe "centos_cloud::nova-compute"
include_recipe "centos_cloud::swift-node"

#include_recipe "centos_cloud::test"

#include_recipe "centos_cloud::monitoring-server"
#include_recipe "centos_cloud::monitoring-client"
