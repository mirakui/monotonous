BASE_DIR = File.join(File.dirname(__FILE__), '..')
$: << BASE_DIR

require 'conf/conf'
require 'lib/twitter_bot_base'

require 'rubygems'
require 'lib/loggable'

class MirakuiMetro < Gena::TwitterBotBase
  def initialize
    super $pit
    log_path = File.join(BASE_DIR, 'log', 'mirakui_retro.log')
    self.logger = Logger.new(log_path, 'daily') unless $DEBUG
    logger.level = $DEBUG ? Logger::DEBUG : Logger::INFO
  end

  def run
    last_id = Var[:last_id] || 0
    from    = SCHEDULE_OFFSET - ($DEBUG ? 1.days : 5.minutes)
    to      = SCHEDULE_OFFSET
    logger.debug "last_id=#{last_id.inspect},from=#{from},to=#{to}"

    schedules = Schedule.find(:all,
      :conditions => [
        "id > :last_id AND posted_at > :from AND posted_at <= :to",
        { :last_id => last_id, :from => from, :to => to } ],
      :order => 'id DESC'
    )

    logger.debug "matched #{schedules.count} statuses"

    if schedules.empty?
      logger.debug "schedule was empty"
      return
    end

    schedules.each do |s|
      status = s.status.gsub('@', '')
      if status.nil? || status.length.zero?
        logger.warn "status was empty: id=#{s.id}"
        next
      end

      post status unless $DEBUG
      logger.info "posted #{s.status_id} #{status}"
    end

    Var[:last_id] = schedules.last.status_id unless $DEBUG
    logger.info "wrote last_id=#{schedules.last.status_id}"
  rescue Object => e
    bt = e.backtrace.join("\n")
    logger.error "#{e.class}:#{e.to_s} -- #{bt}"
  end
end


bot = MirakuiMetro.new
bot.run

__END__

#!/usr/bin/ruby
BASE_DIR = File.dirname(__FILE__)
require 'rubygems'
require 'time'
require 'pit'
require 'logger'
require 'twitter'
require 'pp'
require 'optparse'
require 'uri'
require 'open-uri'
require 'hpricot'
require File.join(BASE_DIR, 'lib/file_db')

$target_file         = Gena::FileDB.new 'tmp/target',         :base=>__FILE__
$since_id_file       = Gena::FileDB.new 'tmp/since_id',       :base=>__FILE__
$reply_since_id_file = Gena::FileDB.new 'tmp/reply_since_id', :base=>__FILE__

$log = Logger.new(File.join(BASE_DIR, 'log', 'doppelkun.log'), 'daily')
$log.level = $DEBUG ? Logger::DEBUG : Logger::INFO

def retarget(tw, target=nil)
  $log.info('begin retarget')

  target_old = $target_file.read
  $log.debug "target_old=#{target_old}"

  if target.nil?
    friends = tw.my(:followers).map {|f| f.screen_name}
    $log.debug "followers=(#{friends.length})#{friends.join ','}"

    target = friends[rand(friends.length)]
  end
  $log.debug "target=#{target}"

  $target_file.write target
  $log.info "target wrote: #{target}"

  since_id = tw.timeline_for(:user, :id=>target).first.id

  $since_id_file.write since_id
  $log.info "wrote since_id #{since_id}"

  #tw.status :post, ". @#{target_old} -> @#{target}"
  tw.status :post, ". @#{target_old} -> ?"
  tw.message :post, 'さようなら', target_old
  tw.message :post, '今日はあなたに決めた', target
  $log.info "retarget @#{target_old} -> @#{target}"

  $log.info 'end retarget'

  target
end

def mirror_post(tw)
  $log.info('begin mirror_post')
  target   = $target_file.read || retarget(tw)

  $log.debug "target=#{target}"
  since_id = $since_id_file.read

  $log.debug "since_id=#{since_id}"

  timeline = since_id ?
    tw.timeline_for(:user, :id=>target, :since_id=>since_id).reverse :
    tw.timeline_for(:user, :id=>target).reverse

  $log.debug "timeline.length=#{timeline.length}"

  unless timeline.empty?
    timeline.each do |t|
      last_id = t.id
      #text = URI.escape(t.text.delete('@'), /[&]/)
      text = t.text
      tw.status :post, text
      $log.debug "poted='#{text}"
      $since_id_file.write last_id
      $log.info "wrote since_id #{last_id}"
    end
    $log.info "posted #{timeline.length} statuses"
  else
    $log.info "no statuses to mirror"
  end
  $log.info 'end mirror_post'

  forward_replies(tw)
end

def forward_replies(tw)
  $log.info('begin forward_replies')
  reply_uri = 'http://twitter.com/statuses/replies.rss'
  target = $target_file.read || retarget(tw)
  auth = [tw.send(:login), tw.send(:password)]
  reply_since_id = $reply_since_id_file.read
  rss = ''
  open(reply_uri, :http_basic_authentication=>auth) do |f|
    rss = f.read
  end
  first = true
  h = Hpricot(rss)
  (h/'item').each do |item|
    status_uri   = (item/'guid').text
    status_id    = status_uri.split('/').last

    if first
      if reply_since_id != status_id
        $reply_since_id_file.write status_id
        $log.info "wrote reply_since_id #{status_id}"
      else
        $log.info "didn't wrote reply_since_id #{status_id}"
      end
      first = false
    end

    if reply_since_id == status_id
      $log.debug "breaked by status_id #{status_id}"
      break
    end

    description  = (item/'description').text
    from, status = *(description.scan(/^([^:\s]+):\s(.*)$/).first)
    status       = URI.escape(status, /[&]/) 
    if from == target 
      $log.info "didn't sent a message because from == target(#{target}), status_id:#{status_id}"
    elsif from == tw.send('login')
      $log.info "didn't sent a message because from == #{target}, status_id:#{status_id}"
    else
      message = "@#{from} が「#{status}」だって"
      tw.message :post, message, target
      $log.info "sent a message '#{message}' to #{target}"
    end
  end

  $log.info('end forward_replies')
end

def announce_target(tw)
  $log.info('begin announce_target')
  target = $target_file.read || retarget(tw)
  status = "今日は @#{target} に憑いてる"
  tw.status :post, status
  $log.info "sent a status '#{status}'"
  $log.info('end announce_target')
end

# main
begin
  task  = ARGV.shift

  pit = Pit.get(
    ($DEBUG ? 'doppelkun_debug' : 'doppelkun'),
    :require=>{'login'=>'','password'=>''}
  )
  $log.debug "pit loaded #{pit['login']}"

  tw = Twitter::Client.new pit

  case task
  when 'retarget'
    retarget(tw, ARGV.shift)
  when 'announce'
    announce_target(tw)
  else
    mirror_post(tw)
  end
rescue Object => e
  $log.error "#{e.class}:#{e.to_str} -- #{e.backtrace}"
end

__END__
