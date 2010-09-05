require 'rubygems'
require 'pit'
require 'open-uri'

LOG_DIR = File.join(File.dirname(__FILE__), '..', 'log')
PAGE_FROM = 1
PAGE_TO   = 16
RETRY_COUNT = 3
RETRY_SLEEP = 1
count = 200
page = 1


pit = Pit.get 'follotter'

(PAGE_FROM..PAGE_TO).each do |page|
  path = File.join LOG_DIR, "statuses.json.#{page}"
  puts "PAGE = #{page}"
  uri = "http://twitter.com/statuses/user_timeline/mirakui.json?count=#{count}&page=#{page}"
  puts uri

  retry_count = 0
  begin
    #open(uri, :http_basic_authentication => [ pit['username'], pit['password'] ]) do |r| 
    open(uri) do |r| 
      open(path, 'w') do |f|
        f.write(r.read)
      end
    end
  rescue => e
    puts "ERROR: #{e.to_s}"
    if (retry_count+=1) <= RETRY_SLEEP
      puts "retrying #{RETRY_SLEEP} seconds later"
      sleep RETRY_SLEEP
      retry
    else
      raise e
    end
  end
  puts "wrote: #{path}"
end

puts "FINISHED"

