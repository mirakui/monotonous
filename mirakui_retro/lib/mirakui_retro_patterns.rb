# vim:fileencoding=utf-8

pattern_regexp /掃除せな/,
do |status|
  pp 'Hello,World'
end

pattern_regexp /掃除せな/,
do |status|
  pp 'Hello,World2'
end

pattern_regexp /今日.*何日/,
do |status|
  msg = "@#{status['user']['screen_name']} "
  msg += ['え？ ',''].sample
  msg += SCHEDULE_OFFSET.to_s
  msg += ['だけど…', 'です', 'すわ'].sample
  pp msg
end
