#!/usr/local/bin/ruby

$ROOTDIR = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift "#{$ROOTDIR}/"
$LOAD_PATH.unshift "#{$ROOTDIR}/libraries/"
require 'chariot'
require "libkaiser"
$chariot = Chariot.new
$chariot.refresh
$chariot.begin
