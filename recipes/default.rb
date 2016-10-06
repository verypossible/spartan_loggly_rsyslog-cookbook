#
# Cookbook Name:: loggly
# Recipe:: default
#
# Copyright (C) 2016 Daniel Searles
# Copyright (C) 2014 Matt Veitas
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Chef::Recipe.public_send(:include, LogglyHelpers)
Chef::Resource.public_send(:include, LogglyHelpers)

fail 'You must define the Loggly token.' if node['loggly']['token'].empty?

# Install rsyslog
include_recipe 'rsyslog::default'

# TLS Configuration
package 'rsyslog-gnutls' do
  action :install
end

assign_default_rsyslog_version if node['loggly']['rsyslog_major_version'].nil?

directory node['loggly']['tls']['cert_path'] do
  owner 'root'
  group node['loggly']['rsyslog_group']
  mode 0750
  action :create
  recursive true
end

crt_file = "#{node['loggly']['tls']['cert_path']}/#{node['loggly']['tls']['cert_file']}"
remote_file 'download loggly.com cert' do
  owner 'root'
  group 'root'
  mode 0644
  path crt_file
  source node['loggly']['tls']['cert_url']
  checksum node['loggly']['tls']['cert_checksum']
  notifies :restart, 'service[rsyslog]', :delayed
end

# resource_exists = proc do
begin
  resources 'execute[validate_config]'
  true
rescue Chef::Exceptions::ResourceNotFound
  execute 'validate_config' do
    command "rsyslogd -N 1 -f #{node['rsyslog']['config_prefix']}/rsyslog.conf"
    action  :nothing
  end
end
# end

# Write out configuration
template node['loggly']['rsyslog']['conf'] do
  helpers(LogglyHelpers)
  source 'rsyslog-loggly.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables(crt_file: crt_file, tags: tags, token: node['loggly']['token'])
  notifies :run, 'execute[validate_config]', :delayed
  notifies :restart, 'service[rsyslog]', :delayed
end

template node['loggly']['rsyslog']['im_file_conf'] do
  helpers(LogglyHelpers)
  source 'input-module-file.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  action :nothing
end

# Write out configs for files
files = configure_files(node['loggly']['log_files'])

template node['loggly']['rsyslog']['files_conf'] do
  helpers(LogglyHelpers)
  source 'files.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables(log_files: files)
  notifies :create, "template[#{node['loggly']['rsyslog']['im_file_conf']}]", :immediate
  notifies :run, 'execute[validate_config]', :delayed
  notifies :restart, 'service[rsyslog]', :delayed
  not_if { files.empty? }
end

# Write out configs for apps
node['loggly']['apps'].each do |app_name, app_log_files|
  files = configure_files(app_log_files)
  file_tags = files.map { |file| file['tag'] }.uniq

  template app_conf(app_name) do
    helpers(LogglyHelpers)
    source 'apps.conf.erb'
    owner 'root'
    group 'root'
    mode 0644
    variables(app_name: app_name,
              format: loggly_format(app_name),
              log_files: files,
              file_tags: file_tags)
    notifies :create, "template[#{node['loggly']['rsyslog']['im_file_conf']}]", :immediate
    notifies :run, 'execute[validate_config]', :delayed
    notifies :restart, 'service[rsyslog]', :delayed
    not_if { files.empty? }
  end
end
