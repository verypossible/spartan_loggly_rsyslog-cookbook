Loggly rsyslog Cookbook
================

[![Circle CI](https://circleci.com/gh/spartansystems/spartan_loggly_rsyslog-cookbook/tree/master.svg?style=svg)](https://circleci.com/gh/spartansystems/spartan_loggly_rsyslog-cookbook/tree/master)

Note: This has been forked from [apetresc/loggly-rsyslog](https://github.com/apetresc/loggly-rsyslog).

Installs and configures rsyslog for use with [Loggly](http://loggly.com).

Supported Versions
------------
- Chef 12
- Ruby 2.1.6
- Ruby 2.2.4
- rsyslog 5.8 through 8.4

Platform
--------
Tested against Ubuntu 12.04, 14.04, 15.04, 16.04
Tested against Centos 6.6, 6.7, 6.8, 7.2.
Tested against Debian 7.11

Attributes
----------
This cookbook leverages the
[rsyslog](https://github.com/chef-cookbooks/rsyslog) to install rsyslog. You
can use any of it's attributes to configure rsyslog further than what this
cookbook exposes.

### `normal['rsyslog']['max_message_size']` (default: '64k')

This cookbook sets the max message size to 64k per Loggly's recommendation.

### `default['loggly']['tags']` (default: [])

Expects an array of strings that will all be set as global tags for the system.

### `default['loggly']['log_files']` (default: [])

Set up rsyslog to watch files and send contents off to loggly.

Expects an array of Hashes with the following keys:

* `filename`  (required)
  - an absolute path to the file
* `tag`       (optional)
  - a tag to attach to content from the file
  - Default: basename of filename with periods replaced with dashes (e.g. `/d/f.log` -> `f-log`)
* `statefile` (optional)
  - an absolute path to the rsyslog statefile
  - Default: the filename path with `.rsyslog_state` appended (e.g. `/d/f.log` -> `/d/f.log.rsyslog_state`)
* `severity`  (optional)
  - the rsyslog severity for the contents of the file
  - Default: the severity will be omitted from the config if it isn't set. Rsyslog will default it to `Info`

Example:

```
  node.default['loggly']['log_files'] = [
    { 'filename' => '/string/key.file.ext' },
    { filename: '/just/a/file.log' },
    { filename: '/every/thing.txt', tag: 'all the options', statefile: '/tmp/state', severity: 'Warning' }
  ]
```

### `default['loggly']['apps']` (default: {})

Set up rsyslog to watch a group of related files, and dispatch contents to loggly with a common tag.

This can be used to implement the pattern shown in the loggly docs for [apache](https://www.loggly.com/docs/sending-apache-logs/) and [nginx](https://www.loggly.com/docs/nginx-server-logs/).

Expects a hash.

Each key is used in naming the config file, and also set the common tag sent to loggly.

The values should be an array of files in the format used by `default['loggly']['log_files']`.

In addition to the common application-level tag, each file will have a file-specific tag, which allows differentiating within loggly.

This example will generate a file /etc/rsyslog.d/21-nginx.conf with contents similar to [the nginx manual configuration example](https://www.loggly.com/docs/nginx-server-logs/):
```
  node.default['loggly']['apps'] = {
    'nginx' => [ { 'filename' => '/var/log/nginx/access.log',
                   'statefile' => 'stat-nginx-access',
                   'tag' => 'nginx-access'
                   'severity' => 'info'},
                 { 'filename' => '/var/log/nginx/error.log'
                   'statefile' => 'stat-nginx-error',
                   'tag' => 'nginx-error',
                   'severity' => 'error' }
    ]
  }
```

### `default['loggly']['tls']['cert_path']` (default: '/etc/rsyslog.d/keys/ca.d')

The path to save the loggly cert.

### `default['loggly']['tls']['cert_file']` (default: 'logs-01.loggly.com_sha12.crt')

The filename for the loggly cert.

### `default['loggly']['tls']['cert_url']` (default: 'https://logdog.loggly.com/media/logs-01.loggly.com_sha12.crt')

The url from which to fetch the loggly cert.

### `default['loggly']['tls']['cert_checksum']` (default: 'b562ae82b54bcb43923290e78949153c0c64910d40b02d2207010bb119147ffc')

The SHA256 checksum of the cert.

### `default['loggly']['token']` (default: '')

The loggly token. It is best to wrap this cookbook with another cookbook that
gets this secret from a databag or some other secret storage system.

### `default['loggly']['rsyslog']['conf_dir']` (default: '/etc/rsyslog.d')

The rsyslog configuration directory.

### `default['loggly']['rsyslog']['conf']` (default: "#{node['loggly']['rsyslog']['conf_dir']}/22-loggly.conf")

The filename for the loggly rsyslog configuration file.

### `default['loggly']['rsyslog']['files_conf']` (default: "#{node['loggly']['rsyslog']['conf_dir']}/99-files.conf")

The filename for the rsyslog configuration file that will setup rsyslog to watch files for sending to loggly.

### `default['loggly']['rsyslog']['host']` (default: 'logs-01.loggly.com')

The host for rsyslog to send logs.

### `default['loggly']['rsyslog']['port']` (default: 6514)

The port for rsyslog to send logs.

### `default['loggly']['rsyslog']['input_file_poll_interval']` (default: 10)

How often rsyslog will check files for new content to send to loggly.

Recipes
-------
Include the default recipe in a cookbook. The cookbook includes the rsyslog
cookbook that will install the rsyslog package and start the service if it does
not exist. The rsyslog service will restart after changes to the loggly rsyslog
or input files configuration file(s) are made.

Running Tests
----------------------------

* Ensure that you have the [chefdk](https://downloads.chef.io/chef-dk/) installed.
* Run: `rake`

You can see the individual rake commands with `rake -T`

License & Authors
-----------------
- Author: Matt Veitas <mveitas@gmail.com>
- Author: Daniel Searles <daniel.paul.searles@gmail.com>

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
