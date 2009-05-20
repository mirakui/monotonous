require 'twitter'
require 'time'
require 'loggable'

module MirakuiDmm
  class MirakuiDmmBase

    include Gena::Loggable

    def initialize
    end

    protected
    def post(msg)
      twitter.status :post, msg
      logger.info "posted to twitter: #{msg}"
    end

    private
    def twitter
      unless defined? @twitter
        pit = Pit.get(
          ($DEBUG ? 'mirakui_dmm_twitter_debug' : 'mirakui_dmm_twitter'),
          :require=>{'login'=>'','password'=>''}
        )
        logger.debug "pit loaded #{pit['login']}"

        @twitter = Twitter::Client.new pit
      end
      @twitter
    end
  end
end

