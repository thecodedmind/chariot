$ROOTDIR = File.expand_path(File.dirname(__FILE__))

$LOAD_PATH.unshift "#{$ROOTDIR}/"
$LOAD_PATH.unshift "#{$ROOTDIR}/libraries/"

require 'codedmind'
require "libkaiser"

r = CodedMind.new

r.load_directory "#{$ROOTDIR}/brains/"
#puts r.data["subs"]
#puts r.data["arrays"]
#puts r.data["topics"]
while true
  print("> ")
  bot = r.reply "admin", gets.chomp
  puts bot
end
