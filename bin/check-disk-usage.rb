#! /usr/bin/env ruby
# frozen_string_literal: false

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

#
# Check Disk
#
class CheckDisk < Sensu::Plugin::Check::CLI
  include Sys
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

  option :includemnt,
         description: 'Include only mount point(s)',
         short: '-I MNT[,MNT]',
         proc: proc { |a| a.split(',') }

  option :ignorepathre,
         short: '-p PATHRE',
         description: 'Ignore mount point(s) matching regular expression',
         proc: proc { |a| Regexp.new(a) }

  option :ignoreopt,
         short: '-o TYPE[.TYPE]',
         description: 'Ignore option(s)',
         proc: proc { |a| a.split('.') }

  option :ignorereadonly,
         long: '--ignore-readonly',
         description: 'Ignore read-only filesystems',
         boolean: true,
         default: false

  option :ignore_reserved,
         description: 'Ignore bytes reserved for privileged processes',
         short: '-r',
         long: '--ignore-reserved',
         boolean: true,
         default: false

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

  option :magic,
         short: '-m MAGIC',
         description: 'Magic factor to adjust warn/crit thresholds. Example: .9',
         proc: proc(&:to_f),
         default: 1.0

  option :normal,
         short: '-n NORMAL',
         description: 'Levels are not adapted for filesystems of exactly this '\
          'size, where levels are reduced for smaller filesystems and raised '\
          'for larger filesystems.',
         proc: proc(&:to_f),
         default: 20

  option :minimum,
         short: '-l MINIMUM',
         description: 'Minimum size to adjust (in GB)',
         proc: proc(&:to_f),
         default: 100

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
    begin
      mounts = Filesystem.mounts
    rescue StandardError
      unknown 'An error occured getting the mount info'
    end
    mounts.each do |line|
      begin
        next if config[:fstype] && !config[:fstype].include?(line.mount_type)
        next if config[:ignoretype]&.include?(line.mount_type)
        next if config[:ignoremnt]&.include?(line.mount_point)
        next if config[:ignorepathre]&.match(line.mount_point)
        next if config[:ignoreopt]&.include?(line.options)
        next if config[:ignorereadonly] && line.options.split(',').include?('ro')
        next if config[:includemnt] && !config[:includemnt].include?(line.mount_point)
      rescue StandardError
        unknown 'An error occured getting the mount info'
      end
      check_mount(line)
    end
  end

  # Adjust the percentages based on volume size
  #
  def adj_percent(size, percent)
    hsize = (size / (1024.0 * 1024.0)) / config[:normal].to_f
    felt  = hsize**config[:magic]
    scale = felt / hsize
    100 - ((100 - percent) * scale)
  end

  def check_mount(line)
    begin
      fs_info = Filesystem.stat(line.mount_point)
    rescue StandardError
      @warn_fs << "#{line.mount_point} Unable to read."
      return
    end
    if line.mount_type == 'devfs'
      return
    end

    if fs_info.respond_to?(:inodes) && !fs_info.inodes.nil? # needed for windows
      percent_i = percent_inodes(fs_info)
      if percent_i >= config[:icrit]
        @crit_fs << "#{line.mount_point} #{percent_i}% inode usage"
      elsif percent_i >= config[:iwarn]
        @warn_fs << "#{line.mount_point} #{percent_i}% inode usage"
      end
    end
    percent_b = percent_bytes(fs_info)

    if fs_info.bytes_total < (config[:minimum] * 1_000_000_000)
      bcrit = config[:bcrit]
      bwarn = config[:bwarn]
    else
      bcrit = adj_percent(fs_info.bytes_total, config[:bcrit])
      bwarn = adj_percent(fs_info.bytes_total, config[:bwarn])
    end

    used = to_human(fs_info.bytes_used)
    total = to_human(fs_info.bytes_total)

    if percent_b >= bcrit
      @crit_fs << "#{line.mount_point} #{percent_b}% bytes usage (#{used}/#{total})"
    elsif percent_b >= bwarn
      @warn_fs << "#{line.mount_point} #{percent_b}% bytes usage (#{used}/#{total})"
    end
  end

  def to_human(size)
    unit = [
      [1_099_511_627_776, 'TiB'],
      [1_073_741_824, 'GiB'],
      [1_048_576, 'MiB'],
      [1024, 'KiB'],
      [0, 'B']
    ].detect { |u| size >= u[0] }
    format(
      "%.2f #{unit[1]}",
      (size >= 1024 ? size.to_f / unit[0] : size)
    )
  end

  # Determine the percent inode usage
  #
  def percent_inodes(fs_info)
    (100.0 - (100.0 * fs_info.inodes_free / fs_info.inodes)).round(2)
  end

  # Determine the percent byte usage
  #
  def percent_bytes(fs_info)
    if config[:ignore_reserved]
      u100 = fs_info.bytes_used * 100.0
      nonroot_total = fs_info.bytes_used + fs_info.bytes_available
      if nonroot_total.zero?
        0
      else
        (u100 / nonroot_total + (u100 % nonroot_total != 0 ? 1 : 0)).round(2)
      end
    else
      (100.0 - (100.0 * fs_info.bytes_free / fs_info.bytes_total)).round(2)
    end
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
