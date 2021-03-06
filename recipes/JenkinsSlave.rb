#
# Cookbook Name:: jenkins-server
# Recipe:: JenkinsSlave
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

instance = search("aws_opsworks_instance", "self:true").first

unless instance.nil?
  package 'emacs'
  package 'automake'
  package 'autoconf'
  package 'bison'
  package 'flex'
  package 'make'
  package 'libtool'
  package 'git'
  package 'mercurial'

  if (instance['os'] == 'Amazon Linux 2015.09')
    package 'gettext-devel'
    package 'libxml2-devel'
    package 'pcre-devel'
    package 'openssl-devel'
    package 'bzip2-devel'
    package 'unixODBC-devel'
  end

  if (instance['os'] == 'Ubuntu 14.04 LTS')
    package 'openjdk-7-jdk'
    package 'libxml2-dev'
    package 'libpcre3-dev'
    package 'libssl-dev'
    package 'libbz2-dev'
    package 'libreadline-dev'
    package 'unixodbc-dev'
  end

  ssh_public_key_file = File.join(Chef::Config[:file_cache_path], 'cookbooks/aws_chef_jenkins/files/default/id_rsa_test.pub')
  ssh_public_key = File.read(ssh_public_key_file)

  if (instance['os'] == 'Amazon Linux 2015.09')
    append_if_no_line "ec2-user_key" do
      path "/home/ec2-user/.ssh/authorized_keys"
      line "#{ssh_public_key}"
    end
  end

  if (instance['os'] == 'Ubuntu 14.04 LTS')
    append_if_no_line "ubuntu-user_key" do
      path "/home/ubuntu/.ssh/authorized_keys"
      line "#{ssh_public_key}"
    end
  end
end
