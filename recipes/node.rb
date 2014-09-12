#
# Cookbook Name:: centos-cloud
# Recipe:: node
#
# Copyright 2013, cloudtechlab
#
# All rights reserved - Do Not Redistribute
#
include_recipe "centos_cloud::nova-compute-kvm"
include_recipe "centos_cloud::swift-node"
include_recipe "centos_cloud::monitoring-client"
