#!/usr/bin/ruby
require 'rubygems'
require 'time'
require 'pit'
require 'net/http'
require 'logger'
require 'twitter'
require 'pp'
require 'pathname'

FAVOTTER_DOMAIN = 'favotter.matope.com'
QUERY = '/rss.php?mode=new'
BASE_PATH = File.dirname(__FILE__)
STATUS_FILE = BASE_PATH + '/log/status'
MSG_FILE = {
  'alive'=> BASE_PATH+'/config/alive.msg',
  'dead' => BASE_PATH+'/config/dead.msg'
}
LOG_FILE = BASE_PATH + '/log/favotter503.log'
LOG_LEVEL = Logger::DEBUG

$log = Logger.new(LOG_FILE, 'daily')
$log.level = LOG_LEVEL
pit = Pit.get('favotter503', :require=>{
  'login' => 'favotter503',
  'password' => ''
})

$tw = Twitter::Client.new pit

def post(msg)
  $log.debug "msg: #{msg}"
  $tw.status(:post, msg)
end

def select_msg(type)
  lines = nil
  open(MSG_FILE[type],'r') {|f| lines = f.read.split(/\n/)}
  lines[rand(lines.length)]
end


http = Net::HTTP.new(FAVOTTER_DOMAIN)
res = http.get(QUERY)

status = res.code
status_old = File.exist?(STATUS_FILE) ? open(STATUS_FILE, 'r').read.chomp : nil
changed = (status[0]!=status_old[0])

$log.debug res.code
if changed
  if res.code=="200"
    post(select_msg('alive'))
  else
    post(select_msg('dead'))
  end
end

open(STATUS_FILE, 'w').write(status)


