#
# Cookbook Name:: chef-server-etcd
# Recipe:: default
#
# Author:: Stephan Renatus (<s.renatus@cloudbau.de>)
#
# Copyright 2013, cloudbau GmbH
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

# avoid downloading again
node.normal['chef-server']['package_file'] = '/tmp/chef-server_11.0.8-1.ubuntu.12.04_amd64.deb'

node.normal['chef-server']['configuration']['api_fqdn'] = etcd['chef-server']['configuration']['api_fqdn']
Chef::Log.info "chef-server/configuration/api_fqdn: #{node['chef-server']['configuration']['api_fqdn']}"

include_recipe 'chef-server'

# room for improvement:
%w{ chef-validator.pem admin.pem }.each do |pem|
  ruby_block "push #{pem} to etcd" do
    block do
      Etcd.client(host: Chef::Config[:etcd_host], port: Chef::Config[:etcd_port]).set("/chef-server/#{pem}", ::File.open("/etc/chef-server/#{pem}").read)
    end
  end
end

ruby_block "push knife.rb to etcd" do
  block do
    knife_rb=<<-EOF
node_name         'admin'
client_key        'admin.pem'
validation_client 'chef-validator'
validation_key    'chef-validator.pem'
chef_server_url   "https://#{node['chef-server']['configuration']['api_fqdn']}"
EOF
    Etcd.client(host: Chef::Config[:etcd_host], port: Chef::Config[:etcd_port])
        .set("/chef-server/knife.rb", knife_rb)
  end
end
