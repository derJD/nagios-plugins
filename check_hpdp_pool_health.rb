#!/usr/bin/ruby
# Script: check_hpdp_pool_health.rb
#
# This script is checking poolhealth for
# monitoring with nagios/icinga. This check gives
# you information about the number of media in
# a pool and their condition.
# ----------------------------------------------------
#
# Version: 0.1.0
# License: GPL
# Author: Jean-Denis Gebhardt <jd@der-jd.de>
#
# Copyright (c) 2016 Jean-Denis Gebhardt
#

require 'pp'
require 'json'
require 'optparse'

options    = {}
msg        = []
ex         = []

OptionParser.new do |opts|
  opts.banner    = "Usage: check_hpdp_pool_health.rb [options]"
  options        = {
    :pool          => "ceph_ma._.weeks",
    :warning       => 3,
    :critical      => 1 }

  opts.on('-p', '--pool <pool_name>', 'name of pool to check (regex possible)') { |v| options[:pool] = v }
  opts.on('-w', '--warning <Mediacount warning>', 'Number of media left raising warning') { |v| options[:warning] = v.to_i }
  opts.on('-c', '--critical <Mediacount critical>', 'Number of media left raising critical') { |v| options[:critical] = v.to_i }
  opts.on_tail('-h', '--help', 'Show this help message') do
    puts opts
    exit 3
  end
end.parse!

class Pool
  attr_accessor :name

  def initialize(name = "")
    self.name    = name
  end

  def self.add_freepool(pool = {})
    unless pool[:freepool] == "None"
      fp   = Pool.detail(pool[:freepool]) unless pool[:freepool] == "None"
      pool[:appendable] += fp[:appendable]
      pool[:media]      += fp[:media]
      pool[:free]       += fp[:free]
      pool[:full]       += fp[:full]
      pool[:good]       += fp[:good]
      pool[:fair]       += fp[:fair]
      pool[:poor]       += fp[:poor]
      pool[:size]       += fp[:size]
      pool[:used]       += fp[:used]
      pool[:labels]     += fp[:labels]
    end

    return pool
  end

  def self.detail(pool = @name)
    return "no pool selected" if pool.nil? || pool.empty?
    @details = self.list(pool)["#{ pool }"]

    @lines = `/opt/omni/bin/omnimm -show_pool "#{ pool }" -detail`.split("\n")
    @lines.each do |line|
      @details[:policy]    = line.match(/.*: (.+)\s+$/)[1].sub(/\s+$/, '') if line.match(/Policy/)
      @details[:used]      = line.match(/.*: (\S+)/)[1].to_i if line.match(/Blocks used/)
      @details[:size]      = line.match(/.*: (\S+)/)[1].to_i if line.match(/Blocks total/)
      @details[:age]       = line.match(/.*: (.+)\t\s+/)[1] if line.match(/Medium age limit/)
      @details[:overrides] = line.match(/.*: (\S+)/)[1] if line.match(/Maximum overwrites/)
      @details[:magazine]  = line.match(/.*: (\S+)/)[1] if line.match(/Magazine support/)
      @details[:freepool]  = line.match(/.*: (\S+)/)[1] if line.match(/Free pool support.+None/)
      @details[:freepool]  = line.match(/.*\((.*)\).*|.*(None).*/)[1] if line.match(/Free pool support.+\(/)
    end

    @lines = `/opt/omni/bin/omnirpt -report media_list -tab -pool #{ pool.inspect }`.split("\n")
    @lines.each do |line|
      @data = line.split("\t")
      @details[:labels] ||= []
      @details[:labels] << @data[1].sub(/.+\] /, '') unless line.match(/^#/)
    end

    return @details
  end

  def self.list(pool = "")
    @pool = pool.empty? ? "" : "-pool #{ pool.inspect }"

    @pools = `/opt/omni/bin/omnirpt -report pool_list -tab #{ @pool }`
    @pools.split("\n").each do |line|
      @data = line.split("\t")
      @list ||= {}
      @list["#{ @data[0] }"] = {
        :description => @data[1],
        :type        => @data[2],
        :full        => @data[3].to_i,
        :appendable  => @data[4].to_i,
        :free        => @data[5].to_i,
        :poor        => @data[6].to_i,
        :fair        => @data[7].to_i,
        :good        => @data[8].to_i,
        :media       => @data[9].to_i } unless line.match(/^#/)
    end

    return @list
  end
end

match = `/opt/omni/bin/omnimm -show_pool | /bin/awk '$0 ~ /#{ options[:pool] }/ {print $2}'`.split
if match.empty?
  puts "No Pool found matching #{ options[:pool] }!"
  exit 1
end

match.each do |p|
  pool = Pool.detail(p)
  pool = Pool.add_freepool(pool) unless pool[:freepool] == "None"

  case
    when (pool[:free] + pool[:appendable]) <= options[:critical] then
      msg << "CRITICAL: Pool #{ p.inspect } has less/equal #{ options[:critical] } writable media left!"
      ex  << 2
    when pool[:poor] > 0 then
      msg << "CRITICAL: Pool #{ p.inspect } contains #{ pool[:poor] } media with status poor!"
      ex  << 2
    when (pool[:free] + pool[:appendable]) <= options[:warning] then
      msg << "WARNING: Pool #{ p.inspect } has less/equal #{ options[:warning] } writable media left!"
      ex  << 1
    when pool[:media] == 0 then
      msg << "WARNING: Pool #{ p.inspect } is empty!"
      ex  << 1
    when pool[:fair] > 0 then
      msg << "WARNING: Pool #{ p.inspect } contains #{ pool[:fair] } media with status fair!"
      ex  << 1
    when pool[:media] == pool[:good] then 
      msg << "OK: All media in pool #{ p.inspect } in good shape"
      ex  << 0
  end
end

puts msg.join("\n")
exit ex.max
