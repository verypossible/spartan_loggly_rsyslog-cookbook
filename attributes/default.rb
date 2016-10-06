# This is the current suggested size from loggly.
normal['rsyslog']['max_message_size'] = '64k'

default['loggly']['tags'] = []

default['loggly']['log_files'] = []
default['loggly']['apps'] = {}

default['loggly']['tls']['cert_path'] = '/etc/rsyslog.d/keys/ca.d'
default['loggly']['tls']['cert_file'] = 'logs-01.loggly.com_sha12.crt'
default['loggly']['tls']['cert_url'] = 'https://logdog.loggly.com/media/logs-01.loggly.com_sha12.crt'
default['loggly']['tls']['cert_checksum'] = 'b562ae82b54bcb43923290e78949153c0c64910d40b02d2207010bb119147ffc'

# If this attribute is not overridden, a default value will be set at
# converge-time, based on lookup from rsysylog_version_by_platform.
# If no match is found, then a default of 7 will be used.
default['loggly']['rsyslog_major_version'] = nil

# TODO: Add more platforms and versions
default['loggly']['rsyslog_versions_by_platform'] = {
  'amazonlinux' => { 2016.0 => 5 },
  'centos' => { 7.0 => 7, 6.0 => 5 },
  'debian' => { 7.0 => 5, 8.0 => 8 },
  'ubuntu' => { 16.04 => 8, 15.04 => 7, 14.04 => 7, 12.04 => 5 }
}

# The rsyslog cookbook sets this for ubuntu but leaves it nil for other
# platforms. However, we want to use 'root' when setting up file permissions.
default['loggly']['rsyslog_group'] = node['rsyslog']['priv_group'] || 'root'

default['loggly']['token'] = ''

default['loggly']['rsyslog']['conf_dir'] = '/etc/rsyslog.d'
default['loggly']['rsyslog']['conf'] = "#{node['loggly']['rsyslog']['conf_dir']}/22-loggly.conf"
default['loggly']['rsyslog']['files_conf'] = "#{node['loggly']['rsyslog']['conf_dir']}/99-files.conf"
default['loggly']['rsyslog']['im_file_conf'] = "#{node['loggly']['rsyslog']['conf_dir']}/20-input-module-file.conf"

default['loggly']['rsyslog']['host'] = 'logs-01.loggly.com'
default['loggly']['rsyslog']['port'] = 6514

default['loggly']['rsyslog']['input_file_poll_interval'] = 10
