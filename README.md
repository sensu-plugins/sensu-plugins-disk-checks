## Sensu-Plugins-disk-checks

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-disk-checks.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-disk-checks)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-disk-checks.svg)](http://badge.fury.io/rb/sensu-plugins-disk-checks)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-disk-checks.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-disk-checks)
[ ![Codeship Status for sensu-plugins/sensu-plugins-disk-checks](https://codeship.com/projects/a78630e0-cc5b-0132-01ab-7a3494c6b360/status?branch=master)](https://codeship.com/projects/76007)
## Functionality

**check-disk-fail**

Check the output of dmesg for a given set of strings that may correspond to a failure

**check-disk**

Check disk capacity and inodes based upon the output of df.

**check-disk-usage**

Check disk capacity and inodes based upon the gem sys-filesystem.

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

**check-smart-status**

Check the SMART status of hardrives and alert based upon a given set of thresholds

**check-smart**

Check the health of a disk using `smartctl`

## Files
 * bin/check-disk-fail.rb
 * bin/check-disk.rb
 * bin/check-disk-usage.rb
 * bin/check-fs-writable.rb
 * bin/check-fstab-mounts.rb
 * bin/check-smart-status.rb
 * bin/check-smart.rb
 * bin/metrics-disk.rb
 * bin/metrics-disk-capacity.rb
 * bin/metrics-disk-usage.rb

## Usage

This is a sample input file used by check-smart-status, see the script for further details.
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
  }
}
```

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Notes
