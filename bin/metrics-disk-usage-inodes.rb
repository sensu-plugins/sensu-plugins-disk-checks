#! /usr/bin/env ruby
#  encoding: UTF-8
#
#   disk-usage-metrics-inodes
#
# DESCRIPTION:
#   This plugin uses df to collect disk capacity metrics
#   disk-usage-metrics.rb looks at /proc/stat which doesnt hold capacity metricss.
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: socket
#
# USAGE:
#
# NOTES:
#   Based on metrics-disk-usage.rb by mattyjones, tas50 and bovy89
#   Basically executes the same code but with different `df` command`
#
#   Also added a metric "total" to get total amount of available inodes
#
#   Use --flatten option to reduce graphite "tree" by using underscores rather
#   then dots for subdirs. Also eliminates 'root' on mounts other than '/'.
#   Keys with --flatten option would be
#    disk_usage.root, disk_usage.boot, and disk_usage.media_sda1
#
#   Mountpoints can be specifically included or ignored using -i or -I options:
#     e.g. disk-usage-metric.rb -i ^/boot,^/media
#
# LICENSE:
#   Copyright 2012 Sonian, Inc <chefs@sonian.net>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'socket'

#
# Disk Usage Metrics
#
class DiskUsageMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.disk_usage"

  option :ignore_mnt,
         description: 'Ignore mounts matching pattern(s)',
         short: '-i MNT[,MNT]',
         long: '--ignore-mount',
         proc: proc { |a| a.split(',') }

  option :include_mnt,
         description: 'Include only mounts matching pattern(s)',
         short: '-I MNT[,MNT]',
         long: '--include-mount',
         proc: proc { |a| a.split(',') }

  option :flatten,
         description: 'Output mounts with underscore rather than dot',
         short: '-f',
         long: '--flatten',
         boolean: true,
         default: false

  option :local,
         description: 'Only check local filesystems (df -l option)',
         short: '-l',
         long: '--local',
         boolean: true,
         default: false

  # Main function
  #
  def run
    delim = config[:flatten] == true ? '_' : '.'
    # Get disk usage from df with used and avail in megabytes
    # #YELLOW
    `df -i #{config[:local] ? '-l' : ''}`.split("\n").drop(1).each do |line|
      _, total, used, avail, used_p, mnt = line.split

      unless %r{/sys[/|$]|/dev[/|$]|/run[/|$]} =~ mnt
        next if config[:ignore_mnt] && config[:ignore_mnt].find { |x| mnt.match(x) }
        next if config[:include_mnt] && !config[:include_mnt].find { |x| mnt.match(x) }
        mnt = if config[:flatten]
                mnt.eql?('/') ? 'root' : mnt.gsub(/^\//, '')
              else
                # If mnt is only / replace that with root if its /tmp/foo
                # replace first occurance of / with root.
                mnt.length == 1 ? 'root' : mnt.gsub(/^\//, 'root.')
              end
        # Fix subsequent slashes
        mnt = mnt.gsub '/', delim
        output [config[:scheme], mnt, 'total'].join('.'), total
        output [config[:scheme], mnt, 'used'].join('.'), used
        output [config[:scheme], mnt, 'avail'].join('.'), avail
        output [config[:scheme], mnt, 'used_percentage'].join('.'), used_p.delete('%')
      end
    end
    ok
  end
end
