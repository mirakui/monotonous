#!/usr/bin/ruby
require 'rubygems'
require 'open-uri'
require 'logger'
require 'gena/pit_mail'

BASE_PATH = File.dirname(__FILE__)
REMOTE_ADDR_URI = 'http://tsuyabu.in/~mirakui/tools/remote_addr.php'
IP_FILE = BASE_PATH + '/log/ip'
LOG_FILE = BASE_PATH + '/log/log'
LOG_LEVEL = Logger::INFO

log = Logger.new(LOG_FILE)
log.level = LOG_LEVEL

ip_old = nil
if File.exist?(IP_FILE)
  open(IP_FILE, 'r') {|f| ip_old = f.read.chomp}
end
open(REMOTE_ADDR_URI) do |res|
  ip = res.read.chomp
  changed = (ip_old != ip)
  if changed
    log.info("#{ip} CHANGED!")
    mail = Gena::PitMail.new 'wanmon_alert'
    mail.send 'subject' => "[alert]IP Changed: #{`hostname`.chomp}",
              'body'    => "IP Changed from #{ip_old} to #{ip}"
  else
    log.debug("#{ip} NOT CHANGED")
  end
  open(IP_FILE, 'w') {|f| f.write ip}
end

