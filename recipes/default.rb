#
# Cookbook Name:: jenkins-server
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
package 'emacs'
package 'automake'
package 'autoconf'
package 'gettext-devel'
package 'libtool'
package 'git'

include_recipe 'jenkins::master'

jenkins_plugin 'greenballs'
jenkins_plugin 'github'
jenkins_plugin 'cmakebuilder'

xml = File.join(Chef::Config[:file_cache_path], 'test3-config.xml')

template xml do
  source 'default/custom-config.xml.erb'
end

# Create a jenkins job (default action is `:create`)
jenkins_job 'test3' do
  config xml
end

service 'jenkins' do
  action [:reload]
end
