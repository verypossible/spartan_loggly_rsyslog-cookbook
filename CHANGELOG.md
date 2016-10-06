# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [3.1.1] - 2016-10-06
### Fixed
- Deprecation warnings from using method attribute accessors.

## [3.1.0] - 2016-09-27
### Added
- Support for nginx apps
- Support for centos-6.8, centos-7.2, ubuntu-16.04
- Support for rsyslog 6

## [3.0.0] - 2016-04-21
### Removed
- Data Bag support.
- Ability to "watch" directories.
- Option to disable TLS.

### Updated
- Loggly rsyslog config to use rsyslog 7 syntax.
- Moved file definitions to their own config file.

## [2.1.3] - 2016-03-03
### Fixed
- cert checksum value to the latest.

## [2.1.2] - 2016-03-03
### Added
- .editorconfig file.

### Fixed
- refactoring name to spartan_loggly_rsyslog.

## 2.1.1 - 2016-03-03
- Update fork of cookbook to be managed by Spartan.

## 2.0.0
- Use an encrypted databag to retrieve the loggly token instead of a node attribute

## 1.0.1
- Set rsyslog configuration values to be configurable via attributes

## 1.0.0 (1/25/2014)
- Initial cookbook version
- Support for sending messages using TLS
- Configuration for monitoring a list of files
- Configuration for monitoring a list of directories

[Unreleased]: https://github.com/spartansystems/spartan_loggly_rsyslog-cookbookcompare/v3.1.1...HEAD
[3.1.1]: https://github.com/spartansystems/spartan_loggly_rsyslog-cookbookcompare/v3.1.0..v3.1.1
[3.1.0]: https://github.com/spartansystems/spartan_loggly_rsyslog-cookbookcompare/v3.0.0..v3.1.0
[3.0.0]: https://github.com/spartansystems/spartan_loggly_rsyslog-cookbookcompare/v2.1.3...v3.0.0
[2.1.3]: https://github.com/spartansystems/spartan_loggly_rsyslog-cookbookcompare/v2.1.2...v2.1.3
[2.1.2]: https://github.com/spartansystems/spartan_loggly_rsyslog-cookbook/compare/v2.1.1...v2.1.2
