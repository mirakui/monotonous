# vim:fileencodings=utf-8
$: << File.join(File.dirname(__FILE__), '..')
require 'conf/conf.rb'

successed_count = 0
failed_count  = 0

while line = ARGF.gets
  line.chomp!
  tokens = line.split "\t"
  sch = Schedule.new
  sch.status_id = tokens[0]
  sch.posted_at = tokens[1]
  sch.status = tokens[2]
  if sch.save
    successed_count += 1
    print 'o'
  else
    failed_count += 1
    print 'x'
  end
end
puts "\nfinished: successed #{successed_count}, failed #{failed_count}"

