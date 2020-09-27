#! /usr/bin/env ruby
# frozen_string_literal: false

#
#   check-smart
#
# DESCRIPTION:
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#
# NOTES:
#   This is a drop-in replacement for check-disk-health.sh.
#
#   smartctl requires root permissions.  When running this script as a non-root
#   user such as sensu, ensure it is run with sudo.
#
#   Create a file named /etc/sudoers.d/smartctl with this line inside :
#   sensu ALL=(ALL) NOPASSWD: /usr/sbin/smartctl
#
#   Fedora has some additional restrictions : if requiretty is set, sudo will only
#   run when the user is logged in to a real tty.
#   Then add this in the sudoers file (/etc/sudoers), below the line Defaults requiretty :
#   Defaults sensu !requiretty
#
# LICENSE:
#   Copyright 2013 Mitsutoshi Aoe <maoe@foldr.in>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'json'

#
# Disk
#
class Disk
  # Setup variables
  #
  def initialize(name, override, binary)
    @device_path = "/dev/#{name}"
    @smart_available = false
    @smart_enabled = false
    @smart_healty = nil
    @smart_binary = binary
    @override_path = override
    check_smart_capability!
    check_health! if smart_capable?
  end
  attr_reader :capability_output, :health_output, :smart_healthy
  alias healthy? smart_healthy

  # Is the device SMART capable and enabled
  #
  def smart_capable?
    @smart_available && @smart_enabled
  end

  # Is the device SMART capable and enabled
  #
  def device_path
    if @override_path.nil?
      @device_path
    else
      @override_path
    end
  end

  # Check for SMART cspability
  #
  def check_smart_capability!
    output = `sudo #{@smart_binary} -i #{device_path}`

    # Newer smartctl
    @smart_available = !output.scan(/SMART support is:\s+Available/).empty?
    @smart_enabled = !output.scan(/SMART support is:\s+Enabled/).empty?

    unless smart_capable?
      # Older smartctl
      @smart_available = !output.scan(/Device supports SMART/).empty?
      @smart_enabled = !output.scan(/and is Enabled/).empty?
    end

    @capability_output = output
  end

  # Check the SMART health
  #
  def check_health!
    output = `sudo #{@smart_binary} -H #{device_path}`
    @smart_healthy = !output.scan(/PASSED|OK$/).empty?
    @health_output = output
  end
end

#
# Check SMART
#
class CheckSMART < Sensu::Plugin::Check::CLI
  option :smart_incapable_disks,
         long: '--smart-incapable-disks EXIT_CODE',
         description: 'Exit code when SMART is unavailable/disabled on a disk',
         proc: proc(&:to_sym),
         default: :unknown,
         in: %i[unknown ok warn critical]

  option :no_smart_capable_disks,
         long: '--zero-smart-capable-disks EXIT_CODE',
         description: 'Exit code when there are no SMART capable disks',
         proc: proc(&:to_sym),
         default: :unknown,
         in: %i[unknown ok warn critical]

  option :binary,
         short: '-b path/to/smartctl',
         long: '--binary /usr/sbin/smartctl',
         description: 'smartctl binary to use, in case you hide yours',
         required: false,
         default: 'smartctl'

  option :json,
         short: '-j path/to/smart.json',
         long: '--json path/to/smart.json',
         description: 'Path to SMART attributes JSON file',
         required: false,
         default: File.dirname(__FILE__) + '/smart.json'

  # Setup variables
  #
  def initialize
    super
    @devices = []

    # Load in the device configuration
    @hardware = if File.readable?(config[:json])
                  JSON.parse(IO.read(config[:json]), symbolize_names: true)[:hardware][:devices]
                else
                  {}
                end

    scan_disks!
  end

  # Generate a list of all block devices
  #
  def scan_disks!
    `lsblk -nro NAME,TYPE`.each_line do |line|
      name, type = line.split

      if type == 'disk'
        jconfig = @hardware.find { |h1| h1[:path] == name }

        override = !jconfig.nil? ? jconfig[:override] : nil

        device = Disk.new(name, override, config[:binary])

        @devices << device if device.smart_capable?
      end
    end
  end

  # Main function
  #
  def run
    unless @devices.length > 0
      exit_with(
        config[:no_smart_capable_disks],
        'No SMART capable devices found'
      )
    end

    unhealthy_disks = @devices.select { |disk| disk.smart_capable? && !disk.healthy? }
    unknown_disks = @devices.reject(&:smart_capable?)

    if unhealthy_disks.length > 0
      output = unhealthy_disks.map(&:health_output)
      output.concat(unknown_disks.map(&:capability_output))
      critical output.join("\n")
    end

    if unknown_disks.length > 0
      exit_with(
        config[:smart_incapable_disks],
        unknown_disks.map(&:capability_output).join("\n")
      )
    end

    ok 'PASSED'
  end

  # Set exit status and message
  #
  def exit_with(sym, message)
    case sym
    when :ok
      ok message
    when :warn
      warn message
    when :critical
      critical message
    else
      unknown message
    end
  end
end
