#! /usr/bin/env ruby
#
#   check-disk
#
# DESCRIPTION:
#   Uses the sys-filesystem gem to get filesystem mount points disk usage
#   --mounts '/:w75:c90,/boot:w80:c95'
#   mounts are comma-separated
#   warning threshold must be preceeded by the letter w and comes in the second position
#   critical threshold must be preceeded by the letter c and comes in the third position
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
#   check-partition-usage.rb --help
# NOTES:
#
# LICENSE:
#   Copyright 2016 Magic Online - www.magic.fr
#   Heavily inspired from check-disk-usage
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'sys/filesystem'
include Sys

#
# Check Disk Partition Usage
#
class CheckDiskPartitionUsage < Sensu::Plugin::Check::CLI
  option :mounts,
		     short: '-m MOUNTS',
         long: '--mounts MOUNTS',
         description: 'comma-separated mounts with their thresholds. e.g: "/boot:w80:c90"',
         proc: proc { |a| a.split(',') },
         default: '/boot:w80:c90'.split(',')

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
    @mounts = []
    @mounts_av = {}
    @mounts_iv = {}
    @user_mounts = config[:mounts]
    @warnings = {}
    @criticals = {}
    @iwarnings = {}
    @icriticals = {}
  end

  # Get FS Mounts
  #
  def get_fs_mounts
    Filesystem.mounts.each do |line|
      begin
        next if config[:fstype] && !config[:fstype].include?(line.mount_type)
        next if config[:ignoretype] && config[:ignoretype].include?(line.mount_type)
        next if config[:ignoremnt] && config[:ignoremnt].include?(line.mount_point)
        @mounts.push(line.mount_point)
      rescue
        unknown 'An error occured getting the mount info'
      end
    end
    @mounts
  end

  # Check a given mount point
  #
  def check_mount(mount)
    stat = Sys::Filesystem.stat(mount.to_s)
    mb_available = stat.block_size * stat.blocks_available / 1024 / 1024
    mb_available
  end

  # Get FS Info of a given Mount point
  #
  def get_fsinfo(mount)
    fsinfo = ''
    begin
      fsinfo = Sys::Filesystem.stat(mount.to_s)
    rescue => e
      unknown "#{e.message} - Might be a problem with df command requiring root privileges - CentOS 5 ? run df -lh as sensu user and check"
    end
    fsinfo
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

  # Test mounts
  #
  def test_mounts(mounts_xv, is_inode = false)
    unknown 'Could not forge a hash of mounts bytes/inodes' unless mounts_xv.is_a?(Hash)
    @user_mounts.each do |mount|
      mounts_xv.each do |key, value|
        begin
          part = mount.split(':')[0]
          warn = mount.split(':')[1].delete('w').to_f
          crit = mount.split(':')[2].delete('c').to_f
          if part == key
            if is_inode
              @iwarnings[key] = value if value.to_f >= warn
              @icriticals[key] = value if value.to_f >= crit
            else
              @warnings[key] = value if value.to_f >= warn
              @criticals[key] = value if value.to_f >= crit
            end
          end
        rescue
          unknown 'Please mind correcting format of mounts: --mounts \'/boot:w70:c90,/root:w80:c95\''
        end
      end
    end
  end

  # Main Function
  #
  def run
    # Forge percent bytes and inodes
    get_fs_mounts.each do |mount|
      next if config[:ignoremnt] && config[:ignoremnt].include?(mount.to_s)
      @mounts_av[mount] = percent_bytes(get_fsinfo(mount))
      @mounts_iv[mount] = percent_inodes(get_fsinfo(mount))
    end
    test_mounts(@mounts_av, false)
    test_mounts(@mounts_iv, true)

    # Alert
    critical @criticals.inspect if @criticals.size >= 1
    warning @warnings.inspect if @warnings.size >= 1
    critical "Inodes: #{@icriticals.inspect}" if @icriticals.size >= 1
    warning "Inodes: #{@iwarnings.inspect}" if @iwarnings.size >= 1
    ok "All is okay for #{@user_mounts.inspect}"
  end
end
