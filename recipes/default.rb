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

fail 'You must define the Loggly token.' if node.loggly.token.empty?

# Install rsyslog
include_recipe 'rsyslog::default'

# TLS Configuration
package 'rsyslog-gnutls' do
  action :install
end

directory node.loggly.tls.cert_path do
  owner 'root'
  group node.rsyslog.priv_group || 'root'
  mode 0750
  action :create
  recursive true
end

crt_file = "#{node.loggly.tls.cert_path}/#{node.loggly.tls.cert_file}"
remote_file 'download loggly.com cert' do
  owner 'root'
  group 'root'
  mode 0644
  path crt_file
  source node.loggly.tls.cert_url
  checksum node.loggly.tls.cert_checksum
  notifies :restart, 'service[rsyslog]', :immediate
end

# Set up tags
tags = node.loggly.tags || []
tags = tags.map { |tag| "tag=\\\"#{tag}\\\"" }.join(' ')

# Determine whether to use 6.x and lower syntax in configuration
use_version6_syntax = false

ruby_block 'installed_rsyslog_version_check' do
  block do
    version_cmd = Mixlib::ShellOut.new('rpm -q rsyslog')
    version_cmd.run_command
    response = version_cmd.stdout.chomp
    # will return something like rsyslog-5.8.10-10.el6_6.x86_64
    major_version = response.match(/^rsyslog-(\d+)/)[1].to_i
    use_version6_syntax = (major_version <= 6)
  end
  only_if { node.platform_family == 'rhel' }
end

# Write out configuration
template node.loggly.rsyslog.conf do
  source 'rsyslog-loggly.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables lazy {
    { crt_file: crt_file,
      tags: tags,
      token: node.loggly.token,
      use_version6_syntax: use_version6_syntax }
  }
  notifies :restart, 'service[rsyslog]', :immediate
end

# Write out configs for files
log_files = node.loggly.log_files.reject { |f| !f.is_a?(Hash) || !f.key?('filename') || f['filename'].strip.empty? }
files = log_files.map do |f|
  f = f.to_h
  f['tag'] = File.basename(f['filename']).tr('.', '-') unless f.key?('tag')
  f['statefile'] = "#{f['filename']}.rsyslog_state" unless f.key?('statefile')
  f
end

template node.loggly.rsyslog.files_conf do
  source 'files.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables(log_files: files)
  notifies :restart, 'service[rsyslog]', :immediate
  not_if { log_files.empty? }
end
