#!/usr/bin/ruby
# Script: check_hpdp_sos_status.rb
#
# This script is parsing output of storeonceinfo
# to make it usefull for monitoring with nagios/icinga
#
# ----------------------------------------------------
#
# Version: 0.2.0
# License: GPL
# Author: Jean-Denis Gebhardt <jd@der-jd.de>
#
# Copyright (c) 2016 Jean-Denis Gebhardt
#

require 'optparse'
require 'pp'

$options = {}
ex = 3

OptionParser.new do |opts|
  opts.banner = "Usage: check_hpdp_sos_status.rb [options]"
  $options     = {
    :path       => "/opt/omni/lbin/",
    :limit      => 10,
    :type       => "SOS",
    :host       => "localhost",
    :store      => "B2D" }

  opts.on('-H', '--host <SOS Server>', 'Name of StoreOnceSoftware Server') { |v| $options[:host] = v }
  opts.on('-S', '--store <SOS Store>', 'Name of StoreOnceSoftware Servers Storage') { |v| $options[:store] = v }
  opts.on('-L', '--limit <percent>',   'Percent of free space') { |v| $options[:limit] = v }
  opts.on_tail('-h', '--help', 'Show this help message') do
    puts opts
    exit 3
  end
end.parse!

def list_stores(server = "", store = "")
  stats  = `#{ $options[:path] }/storeonceinfo -list_stores -type=#{ $options[:type] } -host=#{ server } -name=#{ store }`
  if stats.match(/Error/)
    puts "An Error occured"
    puts stats
    exit 3
  end
  status = stats.match(/\s+Store Status:\s+(\w+)/)[1]
  ratio  = stats.match(/\s+Deduplication Ratio:\s+(.*)/)[1]

  return {
    :status => "#{ status }",
    :ratio  => "#{ ratio }"
  }
end

def get_server_properties(server = "")
  stats = `#{ $options[:path] }/storeonceinfo -get_server_properties -type=#{ $options[:type] } -host=#{ server }`
  if stats.match(/Error/)
    puts "An Error occured"
    puts stats
    exit 3
  end
  size  = stats.match(/\s+Disk Size:\s+(\d+)/)[1].to_f
  avail = stats.match(/\s+Disk Free:\s+(\d+)/)[1].to_f

  return {
    :size    => (size).to_f,
    :avail   => (avail).to_f,
    :percent => (avail / size * 100).to_f
  }
end


store = list_stores($options[:host], $options[:store]).merge(get_server_properties($options[:host]))

if store[:status] == "Online"
  puts "OK: #{ $options[:store] } is #{ store[:status] }."
  puts "Dedupratio: #{ store[:ratio] }"
  puts "#{ sprintf( "%0.02f", store[:percent])}% of Space left on device"
  ex = 0
end

if store[:percent] < $options[:limit]
  puts "WARNING: Only #{ sprintf( "%0.02f", store[:percent]) }% Space left on device"
  puts "Status #{ $options[:store] }: #{ store[:status] }"
  ex = 1
end

unless store[:status] == "Online"
  puts "Critical: #{ $options[:store] } is not up. Current status => #{ store[:status] }"
  ex = 2
end

exit ex
