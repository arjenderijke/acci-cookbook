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
jenkins_plugin 'xunit'

secretsfilename = File.join(Chef::Config[:file_cache_path], 'cookbooks/aws_chef_jenkins/files/default/', node['secretsfilename'])
secretsfile = File.read(secretsfilename)
secretsobject = JSON.parse(secretsfile)

template "#{node['jenkins']['master']['home']}/hudson.tasks.Mailer.xml" do
  source 'default/mailer-plugin.xml.erb'
  variables :mailer => {
              'default-suffix' => '@astrocompute-ci.org',
              'smtp-port' => 587,
              'smtp-username' => secretsobject['smtp'].first['username'],
              'smtp-password' => secretsobject['smtp'].first['password']
            }
  notifies :reload, 'service[jenkins]', :delayed
end

# Create a jenkins job (default action is `:create`)
# Look in the readme to see why we setup the config file like this.
xml = File.join(Chef::Config[:file_cache_path], 'cookbooks/aws_chef_jenkins/files/default/MonetDBCompile-config.xml')

jenkins_job 'MonetDBCompile' do
  config xml
end

service 'jenkins' do
  action [:reload]
end

secretsobject['jenkins_users']['passwords'].each do |password|
  jenkins_password_credentials "#{password['name']}" do
    username "#{password['username']}"
    description "account #{password['username']} on slave"
    password "#{password['password']}"
  end
end

secretsobject['jenkins_users']['ssh_keys'].each do |sshkey|
  ssh_private_key_file = File.join(Chef::Config[:file_cache_path], 'cookbooks/aws_chef_jenkins/files/default', sshkey['keyname'])
  ssh_private_key = File.read(ssh_private_key_file)
  jenkins_private_key_credentials "#{sshkey['name']}" do
    username "#{sshkey['username']}"
    description "account #{sshkey['username']} on slave"
    private_key "#{ssh_private_key}"
  end
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
#end
