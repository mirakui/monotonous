# vim:fileencodings=utf-8
require 'rubygems'
require 'json'
require 'pp'
require 'time'

LOG_DIR = File.join(File.dirname(__FILE__), '..', 'log')
PAGE_FROM = 1
PAGE_TO   = 16

(PAGE_FROM..PAGE_TO).each do |page|
  path = File.join LOG_DIR, "statuses.json.#{page}"
  json = nil
  open(path,'r') {|f| json = JSON.parse(f.read) }

  json.each do |j|
    posted_at  = Time.parse(j['created_at'])
    puts [j['id'], posted_at, j['text']].join("\t")
  end
end


