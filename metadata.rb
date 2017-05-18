name             'spartan_loggly_rsyslog'
maintainer       'Daniel Searles'
maintainer_email 'dsearles@joinspartan.com'
license          'Apache 2.0'
source_url       'https://github.com/spartansystems/spartan_loggly_rsyslog-cookbook'
issues_url       'https://github.com/spartansystems/spartan_loggly_rsyslog-cookbook/issues'
description      'Configures rsyslog to send logs to Loggly'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '3.1.2'

supports 'ubuntu', '>= 14.04'
supports 'centos', '>= 6.6'

depends 'rsyslog', '~> 6.0.1'
