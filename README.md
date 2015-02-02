## Sensu-Plugins-disk-checks

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-disk-checks.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-disk-checks)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-disk-checks.svg)](http://badge.fury.io/rb/sensu-plugins-disk-checks)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks)

## Functionality

**check-disk-fail**

Check the output of dmesg for a given set of strings that may correspond to a failure

**check-disk**

Check disk capacity and inodes based upon the output of df.

**check-fs-writeable**

Check to make sure a filesytem is writable.  This will check both proc and do a smoke test of each given mountpoint.  It can also auto-discover mount points in the self namespace.

**check-fstab-mounts**

Check the mount points in */etc/fstab* to ensure they are all accounted for.

**disk-capacity-metrics**

Acquire disk capacity metrics from `df` and convert them to a form usable by graphite

**disk-metrics**

Read */proc/iostats* for disk metrics and put them in a form usable by Graphite.  See [iostats.txt](http://www.kernel.org/doc/Documentation/iostats.txt) for more details.

**disk-usage-metrics**

Based on disk-capacity-metrics.rb by bhenerey and nstielau. The difference here being how the key is defined in graphite and the size we emit to graphite(now using megabytes), inode info has also been dropped.


## Files
 * bin/check-disk-fail.rb
 * bin/check-process-restart.rb
 * bin/check-process.rb

## Installation


Add the public key (if you haven’t already) as a trusted certificate

```
gem cert --add <(curl -Ls https://raw.githubusercontent.com/sensu-plugins/sensu-plugins.github.io/master/certs/sensu-plugins.pem)
gem install <gem> -P MediumSecurity
```

You can also download the key from /certs/ within each repository.

`gem install sensu-plugins-disk-checks`

Add *sensu-plugins-disk-checks* to your Gemfile, manifest, cookbook, etc

## Notes
