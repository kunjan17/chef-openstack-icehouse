#
# Cookbook Name:: centos-cloud
# Recipe:: default
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "centos_cloud::ntp-server"
include_recipe "centos_cloud::bash-completion"
include_recipe "centos_cloud::rabbitmq-server"
include_recipe "centos_cloud::keystone"
include_recipe "centos_cloud::swift-proxy"
include_recipe "centos_cloud::glance"
include_recipe "centos_cloud::cinder"
include_recipe "centos_cloud::neutron"
include_recipe "centos_cloud::nova"
include_recipe "centos_cloud::nova-compute"
include_recipe "centos_cloud::swift-node"
include_recipe "centos_cloud::heat"
include_recipe "centos_cloud::ceilometer"
include_recipe "centos_cloud::sahara"
#include_recipe "centos_cloud::dashboard"
#include_recipe "centos_cloud::test"

#include_recipe "centos_cloud::monitoring-server"
#include_recipe "centos_cloud::monitoring-client"
