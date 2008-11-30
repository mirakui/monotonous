#!/usr/bin/ruby
require 'rubygems'
require 'time'
require 'pit'
require 'logger'
require 'twitter'
require 'pp'
require 'optparse'
require 'gena/file_db'

$target_file   = Gena::FileDB.new 'tmp/target',        :base=>__FILE__
$since_id_file = Gena::FileDB.new 'tmp/since_id',      :base=>__FILE__

$log = Logger.new(File.dirname(__FILE__)+'/log/doppelkun.log', 'monthly')
$log.level = $DEBUG ? Logger::DEBUG : Logger::INFO

def retarget(tw, target=nil)
  $log.info('begin retarget')

  target_old = $target_file.read
  $log.debug "target_old=#{target_old}"

  if target.nil?
    friends = tw.my(:followers).map {|f| f.screen_name}
    $log.debug "followers=(#{friends.length})#{friends.join ','}"

    target = friends[rand friends.length]
  end
  $log.debug "target=#{target}"

  $target_file.write target
  $log.info "target wrote: #{target}"

  since_id = tw.timeline_for(:user, :id=>target).first.id

  $since_id_file.write since_id
  $log.info "wrote since_id #{since_id}"

  tw.status :post, "@#{target_old} -> @#{target}"
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
      tw.status :post, t.text
      $log.debug "poted='#{t.text}"
      $since_id_file.write last_id
      $log.info "wrote since_id #{last_id}"
    end
    $log.info "posted #{timeline.length} statuses"
  else
    $log.info "no statuses to mirror"
  end
  $log.info 'end mirror_post'
end

# main
begin
  task  = ARGV.shift

  pit = Pit.get(
    $DEBUG ? 'doppelkun_debug' : 'doppelkun',
    :require=>{'login'=>'','password'=>''}
  )
  $log.debug "pit loaded #{pit['login']}"

  tw = Twitter::Client.new pit

  task=='retarget' ? retarget(tw, ARGV.shift) : mirror_post(tw)
rescue => e
  $log.fatal "#{e.class}:#{e.to_str} -- #{e.backtrace}"
end

__END__
