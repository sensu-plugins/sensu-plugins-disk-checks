#! /usr/bin/env ruby
#
#   check-disk
#
# DESCRIPTION:
#   Uses the sys-filesystem gem to get filesystem mount points and metrics
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux, BSD, Windows
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: sys-filesystem
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright 2015 Yieldbot Inc <Sensu-Plugins>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'sys/filesystem'
include Sys

#
# Check Disk
#
class CheckDisk < Sensu::Plugin::Check::CLI
  option :fstype,
         short: '-t TYPE[,TYPE]',
         description: 'Only check fs type(s)',
         proc: proc { |a| a.split(',') }

  option :ignoretype,
         short: '-x TYPE[,TYPE]',
         description: 'Ignore fs type(s)',
         proc: proc { |a| a.split(',') }

  option :ignoremnt,
         short: '-i MNT[,MNT]',
         description: 'Ignore mount point(s)',
         proc: proc { |a| a.split(',') }

  option :bwarn,
         short: '-w PERCENT',
         description: 'Warn if PERCENT or more of disk full',
         proc: proc(&:to_i),
         default: 85

  option :bcrit,
         short: '-c PERCENT',
         description: 'Critical if PERCENT or more of disk full',
         proc: proc(&:to_i),
         default: 95

  option :iwarn,
         short: '-W PERCENT',
         description: 'Warn if PERCENT or more of inodes used',
         proc: proc(&:to_i),
         default: 85

  option :icrit,
         short: '-K PERCENT',
         description: 'Critical if PERCENT or more of inodes used',
         proc: proc(&:to_i),
         default: 95

  # Setup variables
  #
  def initialize
    super
    @crit_fs = []
    @warn_fs = []
  end

  # Get mount data
  #
  def fs_mounts
    Filesystem.mounts.each do |line|
      begin
        next if config[:fstype] && !config[:fstype].include?(line.mount_type)
        next if config[:ignoretype] && config[:ignoretype].include?(line.mount_type)
        next if config[:ignoremnt] && config[:ignoremnt].include?(line.mount_point)
      rescue
        unknown 'An error occured getting the mount info'
      end
      check_mount(line)
    end
  end

  def check_mount(line)
    fs_info = Filesystem.stat(line.mount_point)
    if fs_info.respond_to?(:inodes) # needed for windows
      percent_i = percent_inodes(fs_info)
      if percent_i >= config[:icrit]
        @crit_fs << "#{line.mount_point} #{percent_i}% inode usage"
      elsif percent_i >= config[:iwarn]
        @warn_fs << "#{line.mount_point} #{percent_i}% inode usage"
      end
    end
    percent_b = percent_bytes(fs_info)
    if percent_b >= config[:bcrit]
      @crit_fs << "#{line.mount_point} #{percent_b}% bytes usage"
    elsif percent_b >= config[:bwarn]
      @warn_fs << "#{line.mount_point} #{percent_b}% bytes usage"
    end
  end

  # Determine the percent inode usage
  #
  def percent_inodes(fs_info)
    (100.0 - (100.0 * fs_info.inodes_free / fs_info.inodes)).round(2)
  end

  # Determine the percent byte usage
  #
  def percent_bytes(fs_info)
    (100.0 - (100.0 * fs_info.bytes_free / fs_info.bytes_total)).round(2)
  end

  # Generate output
  #
  def usage_summary
    (@crit_fs + @warn_fs).join(', ')
  end

  # Main function
  #
  def run
    fs_mounts
    critical usage_summary unless @crit_fs.empty?
    warning usage_summary unless @warn_fs.empty?
    ok "All disk usage under #{config[:bwarn]}% and inode usage under #{config[:iwarn]}%"
  end
end
