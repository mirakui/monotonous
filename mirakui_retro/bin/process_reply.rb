# vim:fileencoding=utf-8
BASE_DIR = File.join(File.dirname(__FILE__), '..')
$: << BASE_DIR

require 'conf/conf'
require 'lib/twitter_bot_base'
require 'lib/loggable'
require 'pp'

class MirakuiRetroProcessReply < Gena::TwitterBotBase

  def initialize
    super $pit
    log_path = File.join(BASE_DIR, 'log', 'process_reply.log')
    #self.logger = Logger.new(log_path, 'daily') unless $DEBUG
    logger = Logger.new(log_path, 'daily') unless $DEBUG
    logger.formatter = Logger::Formatter.new # for active_support/core_ext/logger
                                             # http://api.rubyonrails.org/classes/Logger.html
    # logger.level = $DEBUG ? Logger::DEBUG : Logger::INFO
    logger.level = Logger::DEBUG

    @processed_statuses = {}
    @patterns = []

    eval File.read('lib/mirakui_retro_patterns.rb')
  end

  def process_reply
    last_id = Var[:last_processed_reply_id].to_i
    m = self.mentions(last_id > 0 ? {'since_id' => last_id} : {})
    m.each do |status|
      process_status(status)
    end
  end

  def process_timeline
    last_id = Var[:last_processed_timeline_id].to_i
    m = self.friends_timeline(last_id > 0 ? {'since_id' => last_id} : {})
    m.each do |status|
      process_status(status)
      #Var[:last_processed_timeline_id] = m.first['id'].to_s
    end
  end

  def pattern_regexp(regexp, &block)
    @patterns << {:regexp => regexp, :block => proc {|st| block.call(st);true}}
  end

  def pattern(&block)
    pattern_regexp nil, &block
  end

  def process_status(status)
    unless @processed_statuses.has_key?(status['id'])
      @patterns.each do |ptn|
        if !ptn[:regexp] || status['text']=~ptn[:regexp]
          ptn[:block].call(status) && break
        end
      end
      @processed_statuses[status['id']] = status
      #Var[:last_processed_reply_id] = status['id'].to_s
    end
  end


  def run
    process_reply
    process_timeline
  rescue Object => e
    bt = e.backtrace.join("\n")
    logger.error "#{e.class}:#{e.to_s} -- #{bt}"
  end
end


bot = MirakuiRetroProcessReply.new
bot.logger.debug 'start'
bot.run
bot.logger.debug 'finished'


