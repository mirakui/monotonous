$: << File.dirname(__FILE__)
require 'twitter_oauth'
require 'time'
require 'loggable'

module Gena
  class TwitterBotBase < Gena::Loggable
    attr_reader :pit

    def initialize(pit)
      @pit = pit
    end

    protected
    def update(msg)
      #twitter.status :post, msg
      twitter.update msg
      logger.info "posted to twitter: #{msg}"
    end
    alias :post :update

    def mentions(opt={})
      twitter.mentions(opt)
    end

    def friends_timeline(opt={})
      twitter.friends_timeline(opt)
    end

    private
    def twitter
      unless defined? @twitter
        @twitter = TwitterOAuth::Client.new(
          :consumer_key=>pit['consumer_key'],
          :consumer_secret=>pit['consumer_secret'],
          :token=>pit['access_token'],
          :secret=>pit['access_secret']
        )
      end
      @twitter
      #unless defined? @twitter
      #  raise TwitterBotInvalidPit.new(pit.inspect) unless pit.key?('login') && pit.key?('password')
      #  logger.debug "pit loaded #{pit['login']}"

      #  @twitter = Twitter::Client.new pit
      #end
      #@twitter
    end
  end
end

