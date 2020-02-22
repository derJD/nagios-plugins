#!/usr/bin/ruby
# Script: check_hpdp_pool_size.rb
#
# This script is checking poolusage for
# monitoring with nagios/icinga. This check 
# is also able to group pools together by
# filter (in case of Loadbalancing).
# When filtering the combined usage is monitored
# instead of the single pool.
# ----------------------------------------------------
#
# Version: 0.1.0
# License: GPL
# Author: Jean-Denis Gebhardt <jd@der-jd.de>
#
# Copyright (c) 2016 Jean-Denis Gebhardt
#

require 'optparse'
require 'pp'

options    = {}
list       = {}
usage      = []
ex         = 3

OptionParser.new do |opts|
  opts.banner    = "Usage: check_hpdp_pool_size.rb [options]"
  options        = {
    :pool          => "ceph_ma._.weeks",
    :warning       => 75,
    :critical      => 90,
    :filter        => [] }

  opts.on('-p', '--pool <pool_name>', 'name of pool to check (regex possible)') { |v| options[:pool] = v }
  opts.on('-w', '--warning <percent warning>', 'Percent space raising warning') { |v| options[:warning] = v }
  opts.on('-c', '--critical <percent critical>', 'Percent space raising critical') { |v| options[:critical] = v }
  opts.on('-f', '--filter <filter string>', 'string to group pools') { |v| options[:filter] << v }
  opts.on_tail('-h', '--help', 'Show this help message') do
    puts opts
    exit 3
  end
end.parse!

def get_info(pool = "")
  if pool.empty?
    puts "no poolname given!"
    exit 3
  else
    info = `/opt/omni/bin/omnimm -show_pool #{ pool }`
    used = info.match(/Blocks used \[MB\]    : (\d+)/)[1]
    size = info.match(/Blocks total \[MB\]   : (\d+)/)[1]
    fp   = info.match(/.*Uses free pool \((.*)\).*/).nil? ? "" : "#{ info.match(/.*Uses free pool \((.*)\).*/)[1] }"

    return {
      :size     => (size.to_f / 1024),
      :used     => (used.to_f / 1024),
      :freepool => "#{ fp }" }
  end
end

def get_usage(pool = "", total = 0.00, used = 0.00, warn = 75, crit = 95)
  up = (100.00 * used / total).round

  return "Pool \"#{ pool }\": #{ total.round }GB Total; #{ used.round }GB (#{ up }%) Used | \'Pool Size #{ pool }\'=#{ used.round }GB;#{ (warn.to_f / 100) * total.round };#{ (crit.to_f / 100) * total.round };0;#{ total.round }"
end

def set_group(filter = "", pools = {})
  pools.each do |key, val|
    if key.match(/#{ filter }/) && key != "#{ filter }"
      fp = val[:freepool].nil? || val[:freepool].empty? ? 0.00 : pools[val[:freepool]][:size]

      if pools[filter].nil?
        pools[filter] = {
          :size => val[:size] + fp,
          :used => val[:used] }
      else
        pools[filter] = {
          :size => val[:size] + pools[filter][:size] + fp,
          :used => val[:used] + pools[filter][:used] }
      end
    end
  end
end

def set_ex(filter = "", pools = {}, warn = 75, crit = 90)
  ex = 3
  return ex if filter.empty? || pools.empty?

  pools.each do |key, val|
    if key == filter
      res = 100 * val[:used] / val[:size]
      case
        when res < warn then ex = 0 
        when res >= warn && res < crit then ex = 1
        when res >= crit then ex = 2
        else ex = 3
      end
    end
  end
  return ex
end
###############

p = `/opt/omni/bin/omnimm -show_pool | /bin/awk '$0 ~ /#{ options[:pool] }/ {print $2}'`.split
p.each do |o|
  list[o] = get_info(o)
  fp = list[o][:freepool]

  list[fp] = get_info(fp) unless fp.empty?    
end

options[:filter].each { |filter| set_group(filter, list) }
options[:filter].each do |filter|
  e = set_ex(filter, list).to_i
  ex = e if ex == 3 
  ex = e if (e == 1 || e == 2 ) && e > ex
end

list.each do |key,val|
  unless key.match(/freepool/)
    total = val[:freepool].nil? || val[:freepool].empty? ? val[:size] : val[:size] + list["#{ val[:freepool] }"][:size]
    used  = val[:used]
    usage << get_usage(key, total, used, options[:warning], options[:critical])
  end
end
puts usage.join("\n")

exit ex
