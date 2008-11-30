#!/usr/bin/ruby -d
require 'rubygems'
require 'time'
require 'pit'
require 'logger'
require 'twitter'
require 'pp'
require 'optparse'
require 'gena/file_util'

$target_file   = Gena::FileUtil.new 'tmp/target',   :base=>__FILE__
$since_id_file = Gena::FileUtil.new 'tmp/since_id', :base=>__FILE__

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

$target_user = 'mirakui'

def retarget(tw)
  $log.info('begin retarget')

  friends = tw.my(:followers).map {|f| f.screen_name}
  $log.debug "followers=(#{friends.length})#{friends.join ','}"

  target = friends[rand friends.length]
  $log.debug "target=#{target}"

  $target_file.write target
  $log.info "target wrote"

  if $since_id_file.exist?
    $since_id_file.delete 
    $log.info "since_id deleted"
  end
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
    last_id = timeline.last.id
    $log.debug "last_id=#{last_id}"

    timeline.each do |t|
      st = t.text
      tw.status :post, text
      $log.debug "poted='#{text}"
    end
    $log.info "posted #{timeline.length} statuses"

    $since_id_file.write last_id
    $log.info "wrote last_id #{last_id}"
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

  task=='retarget' ? retarget(tw) : mirror_post(tw)
end
