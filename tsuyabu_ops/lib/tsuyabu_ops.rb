$: << File.dirname(__FILE__)

require 'rubygems'
require 'pit'
require 'loggable'
require 'twitter_bot_base'
require 'digest/sha1'

include Gena::Loggable

class TsuyabuOps < Gena::TwitterBotBase
  BASE_DIR  = File.join(File.dirname(__FILE__), '..')
  LIB_DIR   = File.join(BASE_DIR, 'lib')
  LOG_DIR   = '/var/tsuyabu_ops/log'
  QUEUE_DIR = '/var/tsuyabu_ops/queue'
  QUEUE_MAX = 5

  def initialize
    self.logger = Logger.new File.join(LOG_DIR, 'tsuyabu_ops.log') unless $DEBUG
    logger.level = $DEBUG ? Logger::DEBUG : Logger::INFO
    pit = Pit.get(($DEBUG ? 'tsuyabu_ops_debug' : 'tsuyabu_ops'), :require => {
      'login' => '',
      'password' => ''
    })
    super pit
  end

  def run
    logger.debug 'start running'
    q = queue_files.sort
    logger.info "fetched #{q.length} messages from queue" if $DEBUG || q.length>0

    q[0...QUEUE_MAX].each_with_index do |queue_path, i|
      logger.info "queue #{i+1}/#{[q.length,QUEUE_MAX].min}"
      logger.info "fetched '#{queue_path}'"
      text = open(queue_path).read.chomp
      logger.info "text = '#{text}'"
      post text
      File.delete queue_path
      logger.info "deleted '#{queue_path}'"
    end
    logger.debug 'finish running'
  end

  def queue_files
    Dir.glob(File.join(QUEUE_DIR, '*'))
  end

  def add_queue(msg)
    time_str  = Time.now.strftime('%Y%m%d_%H%M%S')
    rand_str  = Digest::SHA1.hexdigest(rand.to_s)[0...10]
    file_name = File.join(QUEUE_DIR, "ops_#{time_str}_#{rand_str}")
    open(file_name, 'w') do |f|
      f.write msg
    end
    logger.info("wrote queue '#{msg}' #{file_name}")
  end

end

