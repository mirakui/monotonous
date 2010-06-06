# vim:fileencoding=utf-8

on_reply /hi/,
do |status|
  msg = 'はい'
  reply_to status, msg
end

on_reply /今日.*何日/,
do |status|
  msg = ['え？ ',''].sample
  msg += SCHEDULE_OFFSET.to_s
  msg += ['だけど…', 'です', 'すわ'].sample
  reply_to status, msg
end
