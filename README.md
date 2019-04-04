## Sensu-Plugins-disk-checks

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-disk-checks.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-disk-checks)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-disk-checks.svg)](http://badge.fury.io/rb/sensu-plugins-disk-checks)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-disk-checks.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-disk-checks)
[![Sensu Bonsai Asset](https://img.shields.io/badge/Bonsai-Download%20Me-brightgreen.svg?colorB=89C967&logo=sensu)](https://bonsai.sensu.io/assets/sensu-plugins/sensu-plugins-disk-checks)

## Sensu Asset  
  The Sensu assets packaged from this repository are built against the Sensu ruby runtime environment. When using these assets as part of a Sensu Go resource (check, mutator or handler), make sure you include the corresponding Sensu ruby runtime asset in the list of assets needed by the resource.  The current ruby-runtime assets can be found [here](https://bonsai.sensu.io/assets/sensu/sensu-ruby-runtime) in the [Bonsai Asset Index](bonsai.sensu.io).

## Functionality

**check-disk-usage**

Check disk capacity and inodes based upon the gem sys-filesystem.

Can adjust thresholds for larger filesystems by providing a 'magic factor'
(`-m`).  The default, `1.0`, will not adapt threshold percentages for volumes.

The `-l` option can be used in combination with the 'magic factor' to specify
the minimum size volume to adjust the thresholds for.

By default all mounted filesystems are checked.

The `-x` option can be used to exclude one or more filesystem types. e.g.

    check-disk-usage.rb -x debugfs,tracefs

The `-p` option can be used to exlucde specific mount points. e.g.

    check-disk-usage.rb -p /run/lxcfs

It's also possible to use regular expressions with the `-x` or `-p` option

    check-disk-usage.rb -p '(\/var|\/run|\/sys|\/snap)'

Refer to [check_mk's](https://mathias-kettner.de/checkmk_filesystems.html)
documentation on adaptive thresholds.

You can also visualize the adjustment using
[WolframAlpha]([https://www.wolframalpha.com/input/) with the following:

    y = 100 - (100-P)*(N^(1-m))/(x^(1-m)), y = P for x in 0 to 1024

Where P = base percentage, N = normalize factor, and m = magic factor

**check-fstab-mounts**

Check the mount points in */etc/fstab* to ensure they are all accounted for.

**metrics-disk-capacity**

Acquire disk capacity metrics from `df` and convert them to a form usable by graphite

**metrics-disk**

Read */proc/iostats* for disk metrics and put them in a form usable by Graphite.  See [iostats.txt](http://www.kernel.org/doc/Documentation/iostats.txt) for more details.

**metrics-disk-usage**

Based on disk-capacity-metrics.rb by bhenerey and nstielau. The difference here being how the key is defined in graphite and the size we emit to graphite(now using megabytes), inode info has also been dropped.

**check-smart-status**

Check the SMART status of hardrives and alert based upon a given set of thresholds

**check-smart**

Check the health of a disk using `smartctl`

**check-smart-tests**

Check the status of SMART offline tests and optionally check if tests were executed in a specified interval

## Files
 * bin/check-disk-usage.rb
 * bin/check-fstab-mounts.rb
 * bin/check-smart-status.rb
 * bin/check-smart.rb
 * bin/check-smart-tests.rb
 * bin/metrics-disk.rb
 * bin/metrics-disk-capacity.rb
 * bin/metrics-disk-usage.rb

## Usage

This is a sample input file used by check-smart-status and check-smart, see the script for further details.
```json
{
  "smart": {
    "attributes": [
      { "id": 1, "name": "Raw_read_Error_Rate", "read": "left16bit" },
      { "id": 5, "name": "Reallocated_Sector_Ct" },
      { "id": 9, "name": "Power_On_Hours", "read": "right16bit", "warn_max": 10000, "crit_max": 15000 },
      { "id": 10 , "name": "Spin_Retry_Count" },
      { "id": 184, "name": "End-to-End_Error" },
      { "id": 187, "name": "Reported_Uncorrect" },
      { "id": 188, "name": "Command_Timeout" },
      { "id": 193, "name": "Load_Cycle_Count", "warn_max": 300000, "crit_max": 600000 },
      { "id": 194, "name": "Temperature_Celsius", "read": "right16bit", "crit_min": 20, "warn_min": 10, "warn_max": 40, "crit_max": 50 },
      { "id": 196, "name": "Reallocated_Event_Count" },
      { "id": 197, "name": "Current_Pending_Sector" },
      { "id": 198, "name": "Offline_Uncorrectable" },
      { "id": 199, "name": "UDMA_CRC_Error_Count" },
      { "id": 201, "name": "Unc_Soft_read_Err_Rate", "read": "left16bit" },
      { "id": 230, "name": "Life_Curve_Status", "crit_min": 100, "warn_min": 100, "warn_max": 100, "crit_max": 100 }
    ]
  },
  "hardware": {
    "devices": [
	  { "path": "sda", "ignore" : [ 187 ] },
	  { "path": "sdb", "override": "/dev/twa0 -d 3ware,0" }
	]
  }
}
```

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Notes

### Certification Verification

If you are verifying certificates in the gem install you will need the certificate for the `sys-filesystem` gem loaded
in the gem certificate store. That cert can be found [here](https://raw.githubusercontent.com/djberg96/sys-filesystem/ffi/certs/djberg96_pub.pem).
