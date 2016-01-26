#
# Cookbook Name:: jenkins-server
# Recipe:: JenkinsSlave
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
package 'emacs'
package 'automake'
package 'autoconf'
package 'gettext-devel'
package 'libtool'
package 'git'

ssh_public_key_file = File.join(Chef::Config[:file_cache_path], 'cookbooks/aws_chef_jenkins/files/default/id_rsa_test.pub')
ssh_public_key = File.read(ssh_public_key_file)

append_if_no_line "ec2-user_key" do
  path "/home/ec2-user/.ssh/authorized_keys"
  line "#{ssh_public_key}"
end
