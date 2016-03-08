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
jenkins_plugin 'mercurial'
jenkins_plugin 'multiple-scms'

secretsfilename = File.join(Chef::Config[:file_cache_path], 'cookbooks/aws_chef_jenkins/files/default/', node['secretsfilename'])
secretsfile = File.read(secretsfilename)
secretsobject = JSON.parse(secretsfile)

serverinstance = search("aws_opsworks_instance", "self:true").first

unless serverinstance.nil?
  template "#{node['jenkins']['master']['home']}/hudson.tasks.Mailer.xml" do
    source 'default/mailer-plugin.xml.erb'
    variables :mailer => {
                'default-suffix' => '@astrocompute-ci.org',
                'smtp-port' => 587,
                'smtp-username' => secretsobject['smtp'].first['username'],
                'smtp-password' => secretsobject['smtp'].first['password'],
                'public-dns' => serverinstance['public_dns'],
                'reply-to' => 'me@example.com',
                'smtp-host' => 'email-smtp.eu-west-1.amazonaws.com'
              }
    notifies :reload, 'service[jenkins]', :delayed
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
      id "#{sshkey['id']}"
      username "#{sshkey['username']}"
      description "account #{sshkey['username']} on slave"
      private_key "#{ssh_private_key}"
    end
  end

  layer = search("aws_opsworks_layer", "shortname:jenkinsslave").first

  search("aws_opsworks_instance").each do |instance|
    if instance['layer_ids'].include?(layer['layer_id'])
      if (instance['os'] == 'Amazon Linux 2015.09')
        jenkins_ssh_slave 'amzn-slave' do
          description 'Run test suites on amazon linux'
          remote_fs   '/home/ec2-user'
          labels      ['amazon-linux-2015.09']
          host        "#{instance['private_ip']}"
          user        'ec2-user'
          credentials '5cf1b49d-e886-421e-910d-01a97eba4ce1'
        end
      end

      if (instance['os'] == 'Ubuntu 14.04 LTS')
        jenkins_ssh_slave 'ubuntu-slave' do
          description 'Run test suites on ubuntu'
          remote_fs   '/home/ubuntu'
          labels      ['ubuntu-14.04-lts']
          host        "#{instance['private_ip']}"
          user        'ubuntu'
          credentials '4f9a2ab5-99b0-4af9-b452-2ed44eaba4f9'
        end
      end
    end
  end

  # Create a jenkins job (default action is `:create`)
  # Look in the readme to see why we setup the config file like this.
  xml = File.join(Chef::Config[:file_cache_path], 'cookbooks/aws_chef_jenkins/files/default/MonetDBCompile-config.xml')

  template xml do
    source 'default/MonetDBCompile-config.xml.erb'
  end

  jenkins_job 'MonetDBCompile' do
    config xml
    only_if {
      node['jenkins_server']['jobs']['MonetDBCompile']['enabled']
    }
  end

  service 'jenkins' do
    action [:reload]
  end
end
