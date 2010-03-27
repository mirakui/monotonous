$: << File.dirname(__FILE__)
require 'loggable'
require 'open-uri' # patched open-uri

module Gena
  class TwitterException < Exception
  end

  class Twitter
    TWITTER_API_BASE = 'http://twitter.com'

    def initialize
    end

    private
    def request(method, query_hash)
    end
  end

end

#__END__
require 'rubygems'
require 'uri'
require 'pit'

uri = 'http://twitter.com/statuses/update.json'
status = 'hello, world'
body = "&status=#{URI.encode status}"
pit = Pit.get('mirakui_retro_debug', :require => {
  'login' => 'mirakui_retro',
  'password' => ''
})

open(uri, {
  :method => :post,
  :body => body,
  :http_basic_authentication => [pit['login'],pit['password']]
}) do |f|
  puts f.read
end

