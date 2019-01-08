#! /usr/bin/env ruby
# frozen_string_literal: false

#
#   check-fstab-mounts
#
# DESCRIPTION:
#   Check /etc/mtab to ensure all filesystems of the requested type(s) from
#   fstab are currently mounted.  If no fstypes are specified, will check all
#   entries in fstab.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: pathname
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Peter Fern <ruby@0xc0dedbad.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'pathname'

#
# Check Fstab Mounts
#
class CheckFstabMounts < Sensu::Plugin::Check::CLI
  option :fstypes,
         description: 'Filesystem types to check, comma-separated',
         short: '-t TYPES',
         long: '--types TYPES',
         proc: proc { |a| a.split(',') },
         required: false

  # Setup variables
  #
  def initialize
    super
    @fstab = IO.readlines '/etc/fstab'
    @mtab = IO.readlines '/etc/mtab'
    @swap_mounts = IO.readlines '/proc/swaps'
    @missing_mounts = []
  end

  def resolve_device(device)
    if device.start_with?('UUID=')
      uuid = device.split('=')[1]
      path = File.join('/', 'dev', 'disk', 'by-uuid', uuid)
      if File.exist?(path) && File.symlink?(path)
        return File.realpath(path)
      end
    end

    if device.start_with?('LABEL=')
      label = device.split('=')[1]
      path  = File.join('/', 'dev', 'disk', 'by-label', label)
      if File.exist?(path) && File.symlink?(path)
        return File.realpath(path)
      end
    end

    if device.start_with?('/dev/mapper')
      if File.symlink?(device)
        device = File.realpath(device, '/')
      end
    end

    device
  end

  # Check by mount destination (col 2 in fstab and proc/mounts)
  #
  def check_mounts
    @fstab.each do |line|
      next if line =~ /^\s*#/
      next if line =~ /^\s*$/

      fields = line.split(/\s+/)
      next if fields[1] == 'none' || (fields[3].include? 'noauto')
      next if config[:fstypes] && !config[:fstypes].include?(fields[2])

      if fields[2] != 'swap'
        @missing_mounts << fields[1] if @mtab.select { |m| m.split(/\s+/)[1] == fields[1] }.empty?
      else
        @missing_mounts << fields[1] if @swap_mounts.select { |m| m.split(/\s+/)[0] == resolve_device(fields[0]) }.empty? # rubocop:disable Style/IfInsideElse
      end
    end
  end

  # Main function
  #
  def run
    check_mounts
    if @missing_mounts.any?
      critical "Mountpoint(s) #{@missing_mounts.join(',')} not mounted!"
    else
      ok 'All mountpoints accounted for'
    end
  end
end
