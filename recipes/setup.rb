#
# Cookbook Name:: chef-server-etcd
# Recipe:: setup
#
# Author:: Stephan Renatus (<s.renatus@cloudbau.de>)
#
# Copyright (C) 2013 cloudbau GmbH
#
# licensed under the apache license, version 2.0 (the "license");
# you may not use this file except in compliance with the license.
# you may obtain a copy of the license at
# 
#     http://www.apache.org/licenses/license-2.0
# 
# unless required by applicable law or agreed to in writing, software
# distributed under the license is distributed on an "as is" basis,
# without warranties or conditions of any kind, either express or implied.
# see the license for the specific language governing permissions and
# limitations under the license.
# 

directory '/tmp' do
  mode '0777'
end

remote_file '/tmp/etcd-chef.tgz' do
  source 'https://api.github.com/repos/coderanger/etcd-chef/tarball'
end

directory '/tmp/etcd-chef'

execute 'tar --strip-components 1 -zxvf /tmp/etcd-chef.tgz -C /tmp/etcd-chef'

directory '/tmp/cookbooks'

remote_file '/tmp/chef-server.tgz' do
  source 'http://community.opscode.com/cookbooks/chef-server/versions/2_0_0/downloads'
end

execute 'tar zxvf /tmp/chef-server.tgz' do
  cwd '/tmp/cookbooks'
end

# XXX doesn't work, some problem with /tmp (STDERR: sh: 1: : Permission denied)
# script 'build and install etcd-chef' do
#   command <<-EOF
# sed -i "s# + %w(LICENSE README.md ROADMAP.md CHANGELOG.md)##" etcd-chef.gemspec
# /opt/chef-server/embedded/bin/gem build etcd-chef.gemspec
# /opt/chef-server/embedded/bin/gem install etcd-chef-0.1.gem
# EOF
#   cwd '/tmp/etcd-chef'
# end

[
  'sed -i "s# + %w(LICENSE README.md ROADMAP.md CHANGELOG.md)##" etcd-chef.gemspec',
  '/opt/chef-server/embedded/bin/gem build etcd-chef.gemspec',
  '/opt/chef-server/embedded/bin/gem install etcd-chef-0.1.gem'
].each do |cmd|
  execute cmd do
    cwd '/tmp/etcd-chef'
  end
end

# trick embedded chef-server cookook
# https://github.com/opscode/omnibus-chef-server/blob/master/files/chef-server-cookbooks/chef-server/recipes/postgresql.rb#L59
file '/etc/init.d/procps' do
  action :delete
end

# trick opscode's runit_server definition
directory '/opt/chef-server/sv/etcd-chef/supervise/' do
  recursive true
end

execute 'mkfifo /opt/chef-server/sv/etcd-chef/supervise/ok'

# trick upstart
execute 'dpkg-divert --local --rename --add /sbin/initctl'

link '/sbin/initctl' do
  to '/bin/true'
end

directory '/var/log/chef-server/etcd-chef' do
  recursive true
  mode '0700'
end

runit_service 'etcd-chef' do
  options({
    :log_directory => '/var/log/chef-server/etcd-chef'
  }.merge(params))
end
