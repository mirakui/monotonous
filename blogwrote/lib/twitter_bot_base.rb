$: << File.dirname(__FILE__)
require 'twitter'
require 'time'
require 'loggable'

module Gena
  class TwitterBotException < Exception
  end

  class TwitterBotInvalidPit < TwitterBotException
  end

  class TwitterBotBase < Gena::Loggable
    attr_reader :pit

    def initialize(pit)
      @pit = pit
    end

    protected
    def post(msg)
      twitter.status :post, msg
      logger.info "posted to twitter: #{msg}"
    end

    private
    def twitter
      unless defined? @twitter
        raise TwitterBotInvalidPit.new(pit.inspect) unless pit.key?('login') && pit.key?('password')
        logger.debug "pit loaded #{pit['login']}"

        @twitter = Twitter::Client.new pit
      end
      @twitter
    end
  end
end


