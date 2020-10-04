[![Sensu Bonsai Asset](https://img.shields.io/badge/Bonsai-Download%20Me-brightgreen.svg?colorB=89C967&logo=sensu)](https://bonsai.sensu.io/assets/sensu-plugins/sensu-plugins-disk-checks)
[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-disk-checks.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-disk-checks)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-disk-checks.svg)](http://badge.fury.io/rb/sensu-plugins-disk-checks)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-disk-checks)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-disk-checks.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-disk-checks)

## Sensu Disk Checks Plugin
- [Overview](#overview)
- [Usage examples](#usage-examples)
- [Configuration](#configuration)
  - [Sensu Go](#sensu-go)
    - [Asset definition](#asset-definition)
    - [Check definition](#check-definition)
  - [Sensu Core](#sensu-core)
    - [Check definition](#check-definition)
- [Functionality](#functionality)
- [Additional information](#additional-information)
- [Installation from source and contributing](#installation-from-source-and-contributing)

### Overview

This plugin provides native disk instrumentation for monitoring and metrics collection, including: health, usage, and various metrics.

The Sensu assets packaged from this repository are built against the Sensu ruby runtime environment. When using these assets as part of a Sensu Go resource (check, mutator or handler), make sure you include the corresponding Sensu ruby runtime asset in the list of assets needed by the resource.  The current ruby-runtime assets can be found [here](https://bonsai.sensu.io/assets/sensu/sensu-ruby-runtime) in the [Bonsai Asset Index](bonsai.sensu.io)

#### Files
 * bin/check-disk-usage.rb
 * bin/check-fstab-mounts.rb
 * bin/check-smart-status.rb
 * bin/check-smart.rb
 * bin/check-smart-tests.rb
 * bin/metrics-disk.rb
 * bin/metrics-disk-capacity.rb
 * bin/metrics-disk-usage.rb

### Usage examples

#### Help

**check-disk-usage.rb**
```
Usage: check-disk-usage.rb (options)
    -c PERCENT                       Critical if PERCENT or more of disk full
    -w PERCENT                       Warn if PERCENT or more of disk full
    -t TYPE[,TYPE]                   Only check fs type(s)
    -K PERCENT                       Critical if PERCENT or more of inodes used
    -i MNT[,MNT]                     Ignore mount point(s)
    -o TYPE[.TYPE]                   Ignore option(s)
    -p PATHRE                        Ignore mount point(s) matching regular expression
    -x TYPE[,TYPE]                   Ignore fs type(s)
    -I MNT[,MNT]                     Include only mount point(s)
    -r                               Ignore bytes reserved for privileged processes only
    -W PERCENT                       Warn if PERCENT or more of inodes used
    -m MAGIC                         Magic factor to adjust warn/crit thresholds. Example: .9
    -l MINIMUM                       Minimum size to adjust (in GB)
    -n NORMAL                        Levels are not adapted for filesystems of exactly this size, where levels are reduced for smaller filesystems and raised for larger filesystems.
```

**metrics-disk-usage.rb**
```
Usage: metrics-disk-usage.rb (options)
    -B, --block-size BLOCK_SIZE      Set block size for sizes printed
    -f, --flatten                    Output mounts with underscore rather than dot
    -i, --ignore-mount MNT[,MNT]     Ignore mounts matching pattern(s)
    -I, --include-mount MNT[,MNT]    Include only mounts matching pattern(s)
    -l, --local                      Only check local filesystems (df -l option)
        --scheme SCHEME              Metric naming scheme, text to prepend to .$parent.$child
```


### Configuration
#### Sensu Go
##### Asset registration

Assets are the best way to make use of this plugin. If you're not using an asset, please consider doing so! If you're using sensuctl 5.13 or later, you can use the following command to add the asset: 

`sensuctl asset add sensu-plugins/sensu-plugins-disk-checks`

If you're using an earlier version of sensuctl, you can download the asset definition from [this project's Bonsai Asset Index page](https://bonsai.sensu.io/assets/sensu-plugins/sensu-plugins-disk-checks).

##### Asset definition

```yaml
---
type: Asset
api_version: core/v2
metadata:
  name: sensu-plugins-disk-checks
spec:
  url: https://assets.bonsai.sensu.io/73a6f8b6f56672630d83ec21676f9a6251094475/sensu-plugins-disk-checks_5.0.0_centos_linux_amd64.tar.gz
  sha512: 0ce9d52b270b77f4cab754e55732ae002228201d0bd01a89b954a0655b88c1ee6546e2f82cfd1eec04689af90ad940cde128e8867912d9e415f4a58d7fdcdadf
```

##### Check definition

```yaml
---
type: CheckConfig
spec:
  command: "metrics-disk-usage.rb"
  handlers: []
  high_flap_threshold: 0
  interval: 10
  low_flap_threshold: 0
  publish: true
  runtime_assets:
  - sensu-plugins/sensu-plugins-disk-checks
  - sensu/sensu-ruby-runtime
  subscriptions:
  - linux
  output_metric_format: graphite_plaintext
  output_metric_handlers:
  - influx-db
```
#### Sensu Core
##### Check definition
```json
{
  "checks": {
    "metrics-disk-usage": {
      "command": "metric-disk-usage.rb",
      "subscribers": ["linux"],
      "interval": 10,
      "refresh": 10,
      "handlers": ["influxdb"]
    }
  }
}

```

### Functionality

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

### Additional information
The `check-smart.rb` and `check-smart-status.rb` scripts can make use of a json file living on disk in `/etc/sensu/conf.d`with the name `smart.json`. You can see a sample input file used by these scripts below. Please refer to the individual scripts for further details.
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

### Installation

### Sensu Go

See the instructions above for [asset registration](#asset-registration)

### Sensu Core
Install and setup plugins on [Sensu Core](https://docs.sensu.io/sensu-core/latest/installation/installing-plugins/)


### Certification Verification

If you are verifying certificates in the gem install you will need the certificate for the `sys-filesystem` gem loaded in the gem certificate store. That cert can be found [here](https://raw.githubusercontent.com/djberg96/sys-filesystem/ffi/certs/djberg96_pub.pem).
