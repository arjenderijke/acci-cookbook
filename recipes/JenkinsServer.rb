#
# Cookbook Name:: jenkins-server
# Recipe:: JenkinsServer
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
package 'emacs'
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

ssh_private_key_file = File.join(Chef::Config[:file_cache_path], 'cookbooks/aws_chef_jenkins/files/default/id_rsa_test')
ssh_private_key = File.read(ssh_private_key_file)
jenkins_private_key_credentials 'ec2-user-slave' do
  username 'ec2-user'
  description 'account ec2-user on slave'
  private_key "#{ssh_private_key}"
end

layer = search("aws_opsworks_layer", "shortname:jenkinsslave").first

# For unknown reasons, this resource failes to create, while it used
# to work before. Reluctantly do it by hand until the problem is
# fixed.

#search("aws_opsworks_instance").each do |instance|
#  if instance['layer_ids'].include?(layer['layer_id'])
#    # Create a slave launched via SSH
#    jenkins_ssh_slave 'ec2-slaves' do
#      description 'Run test suites'
#      remote_fs   '/home/ec2-user'
#      #labels      ['label']
#
#      # SSH specific attributes
#      host        "#{instance['private_ip']}"
#      user        'ec2-user'
#      credentials 'ec2-user-slave'
#    end
#  end
end
