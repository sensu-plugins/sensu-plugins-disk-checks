#! /usr/bin/env ruby
# frozen_string_literal: false

#
#   check-smart-tests.rb
#
# DESCRIPTION:
#   This script checks S.M.A.R.T. self-tests status and optionally time of last
#   test run
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
# check-smart-tests.rb # Use default options
# check-smart-tests.rb -d /dev/sda,/dev/sdb -l 24 -t 336 # Check smart tests status for
#   /dev/sda and /dev/sdb devices, also check if short tests were run in last 24 hours and
#   extended tests were run in last 14 days(336 hours)
#
# NOTES:
#   The plugin requires smartmontools to be installed and smartctl utility in particular.
#
#   smartctl requires root rights to run, so you should allow sensu to execute
#   this command as root without password by adding following line to /etc/sudoers:
#
#   sensu ALL=(ALL) NOPASSWD: /usr/sbin/smartctl
#
#   Tested only on Debian.
#
# LICENSE:
#   Stanislav Sandalnikov <s.sandalnikov@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.

require 'sensu-plugin/check/cli'

class Device
  attr_accessor :name, :pwh, :str

  def initialize(name, smartctl_executable)
    @name = name
    @exec = smartctl_executable
    @pwh = poweron_hours
    @str = selftest_results
  end

  def poweron_hours
    `sudo #{@exec} -A #{@name}`.split("\n").each do |line|
      columns = line.split
      if columns[1] == 'Power_On_Hours'
        return columns[9]
      end
    end
  end

  def selftest_results
    results = []
    headers = %w[num test_description status remaining lifetime lba_of_first_error]

    `sudo #{@exec} -l selftest #{@name}`.split("\n").grep(/^#/).each do |test|
      test = test.gsub!(/\s\s+/m, "\t").split("\t")
      res = {}

      headers.each_with_index do |v, k|
        res[v] = test[k]
      end

      results << res
    end

    results
  end
end

class CheckSMARTTests < Sensu::Plugin::Check::CLI
  option :executable,
         long: '--executable EXECUTABLE',
         short: '-e EXECUTABLE',
         default: '/usr/sbin/smartctl',
         description: 'Path to smartctl executable'
  option :devices,
         long: '--devices *DEVICES',
         short: '-d *DEVICES',
         default: 'all',
         description: 'Comma-separated list of devices to check, i.e. "/dev/sda,/dev/sdb"'
  option :short_test_interval,
         long: '--short_test_interval INTERVAL',
         short: '-s INTERVAL',
         description: 'If more time then this value passed since last short test run, then warning will be raised'
  option :long_test_interval,
         long: '--long_test_interval INTERVAL',
         short: '-l INTERVAL',
         description: 'If more time then this value passed since last extedned test run, then warning will be raised'

  def initialize
    super
    @devices = []
    @warnings = []
    @criticals = []
    set_devices
  end

  def set_devices
    if config[:devices] == 'all'
      `lsblk -plnd -o NAME`.split.each do |name|
        unless name =~ /\/dev\/loop.*/
          dev = Device.new(name, config[:executable])
          @devices.push(dev)
        end
      end
    else
      config[:devices].split(',').each do |name|
        dev = Device.new(name, config[:executable])
        @devices.push(dev)
      end
    end
  end

  def check_tests(dev)
    if dev.str.empty?
      @warnings << "#{dev.name}: No self-tests have been logged."
      return
    end

    unless dev.str[0]['status'] == 'Completed without error' || dev.str[0]['status'] =~ /Self-test routine in progress/
      @criticals << "#{dev.name}: Last test failed - #{dev.str[0]['status']}"
    end

    unless config[:short_test_interval].nil?
      dev.str.each_with_index do |t, i|
        if t['test_description'] != 'Short offline'
          if i == dev.str.length - 1
            @warnings << "#{dev.name}: No short tests were run for this device in last #{dev.str.length} executions"
          end
          next
        else
          if dev.pwh.to_i - t['lifetime'].to_i > config[:short_test_interval].to_i
            @warnings << "#{dev.name}: More than #{config[:short_test_interval]} hours passed since the last short test"
          end
          break
        end
      end
    end

    # TODO: refactor me
    unless config[:long_test_interval].nil? # rubocop:disable Style/GuardClause
      dev.str.each_with_index do |t, i|
        if t['test_description'] != 'Extended offline'
          if i == dev.str.length - 1
            @warnings << "#{dev.name}: No extended tests were run for this device in last #{dev.str.length} executions"
          end
          next
        else
          if dev.pwh.to_i - t['lifetime'].to_i > config[:long_test_interval].to_i
            @warnings << "#{dev.name}: More than #{config[:long_test_interval]} hours passed since the last extended test"
          end
          break
        end
      end
    end
  end

  def run
    @devices.each do |device|
      check_tests(device)
    end

    if @criticals.any?
      critical @criticals.join(' ')
    elsif @warnings.any?
      warning @warnings.join(' ')
    else
      ok 'All devices are OK'
    end
  end
end
