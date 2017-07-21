# Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]

## [2.4.0] - 2017-07-20
- check-smart.rb: Add path overrides via smart.json (@ArakniD)
- check-smart-status.rb: Add path overrides via smart.json (@ArakniD)

## [2.3.0] - 2017-07-03
### Added
- travis testing on ruby 2.4.1 (@majormoses)

### Fixed
- fixed spelling of "Compatibility" in PR template (@majormoses)
- check-smart.rb: deal with long keys in the info output (@robx)
- check-smart.rb: accept "OK" disk health status (@robx)

## [2.2.0] - 2017-06-24
### Added
- check-smart-tests.rb: a plugin to check S.M.A.R.T. self tests status (@sndl)

## [2.1.0] - 2017-05-04
### Changed
- check-disk-usage.rb: show the decimals for disk usage figures
- check-disk-usage.rb: dont do utilization check of devfs filesystems
- bump sys-filesystem to 1.1.7

### Fixed
- check-fstab-mounts.rb: support swap mounts defined using UUID or LABEL
- check-fstab-mounts.rb: support swap mounts defined using LVM /dev/mapper/*

## [2.0.1] - 2016-06-15
### Fixed
- metrics-disk-capacity.rb: fixed invalid string matching with =~ operator

## [2.0.0] - 2016-06-14
### Changed
- Updated Rubocop to 0.40, applied auto-correct.
- metrics-disk.rb: Now using sysfs instead of lsblk for translating device mapper numbers to names
- check-disk-usage.rb: values =< 1024 will not be modified for display in output

### Removed
- Remove Ruby 1.9.3 support; add Ruby 2.3.0 support

## [1.1.3] - 2016-01-15
### Added
- Add --json option to check-smart-status.rb

### Changed
- Let check-smart-status.rb skip SMART incapable disks

### Fixed
- metrics-disk-usage.rb: fix regular expression in unless statement
- check-disk-usage.rb: fix wrong TiB formatting in to_human function

## [1.1.2] - 2015-12-14
### Added
- check-disk-usage.rb: Add option to include only certain mount points

## [1.1.1] - 2015-12-11
### Fixed
- check-disk-usage.rb fails on Windows with sys-filesystem (1.1.4)
- bump sys-filesystem to 1.1.5

## [1.1.0] - 2015-12-08
### Added
- check-disk-usage.rb: Add ignore option to exclude mount point(s) based on regular expression
- metrics-disk.rb: Add ignore and include options to exclude or include devices

### Fixed
- check-disk-usage.rb: Don't blow up when unable to read a filesystem

### Removed
- Remove dependency on `filesystem` gem

## [1.0.3] - 2015-10-25
### Changed
- Adds Ignore option(s) to check-disk-usage.rb
- Adaptive thresholds

### Adaptive Thresholds

This borrows from check_mk's "df" check, which has the ability to
adaptively adjust thresholds for filesystems based on their sizes.

For example, a hard threshold of "warn at 85%" is quite different
between small filesystems and very large filesystems -  85% utilization
of a 20GB filesystem is arguably more serious than 85% utilization of a
10TB filesystem.

This uses check_mk's original alorithm to optionally adjust the
percentage thresholds based on size, using a "magic factor", a
"normalized size", and a "minium size to adjust".

The magic factor defaults to '1.0', which will not adjust thresholds.
The minimum size defaults to '100' (GB).  Filesystems smaller than this
will not be adapted.

check_mk's documentation has a lot more information on this, including
examples of adjustments based on the magic factor:
https://mathias-kettner.de/checkmk_filesystems.html

## [1.0.2] - 2015-08-04
### Changed
- general cleanup

## [1.0.1] - 2015-07-14
### Changed
- updated sensu-plugin gem to 1.2.0

##[1.0.0] - 2015-07-05
### Changed
- changed metrics filenames to conform to std
- updated Rakefile to remove cruft
- updated documentation links in README and CONTRIBUTING
- updated gemspec to put deps in alpha order

## [0.0.4] - 2015-06-22
### Fixed
- Correct check of inodes method on object fs_info which was always returning false

## [0.0.3] - 2015-06-02
### Fixed
- added binstubs

### Changed
- removed cruft from /lib

## [0.0.2] - 2015-04-21
### Fixed
- deployment issue

## 0.0.1 - 2015-04-21
### Added
- initial release

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/2.4.0...HEAD
[2.4.0]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/2.3.0...2.4.0
[2.3.0]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/2.2.0...2.3.0
[2.2.0]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/2.1.0...2.2.0
[2.1.0]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/2.0.1...2.1.0
[2.0.1]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/1.1.3...2.0.0
[1.1.3]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/1.1.2...1.1.3
[1.1.2]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/1.1.1...1.1.2
[1.1.1]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/1.1.1...1.1.1
[1.1.0]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/1.0.3...1.1.0
[1.0.3]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/0.0.4...1.0.0
[0.0.4]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/0.0.3...0.0.4
[0.0.3]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/0.0.2...0.0.3
[0.0.2]: https://github.com/sensu-plugins/sensu-plugins-disk-checks/compare/0.0.1...0.0.2
