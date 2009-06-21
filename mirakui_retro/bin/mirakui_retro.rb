BASE_DIR = File.join(File.dirname(__FILE__), '..')
$: << BASE_DIR

require 'conf/conf'
require 'lib/twitter_bot_base'

require 'rubygems'
require 'lib/loggable'

class MirakuiMetro < Gena::TwitterBotBase
  def initialize
    super $pit
    log_path = File.join(BASE_DIR, 'log', 'mirakui_retro.log')
    self.logger = Logger.new(log_path, 'daily') unless $DEBUG
    # logger.level = $DEBUG ? Logger::DEBUG : Logger::INFO
    logger.level = Logger::DEBUG
  end

  def run
    last_id = Var[:last_id] || 0
    from    = SCHEDULE_OFFSET - ($DEBUG ? 1.days : 30.minutes)
    to      = SCHEDULE_OFFSET
    logger.debug "last_id=#{last_id.inspect},from=#{from},to=#{to}"

    schedules = Schedule.find(:all,
      :conditions => [
        "id < :last_id AND posted_at > :from AND posted_at <= :to",
        { :last_id => last_id, :from => from, :to => to } ],
      :order => 'id DESC'
    )

    logger.debug "matched #{schedules.count} statuses"

    if schedules.empty?
      logger.debug "schedule was empty"
      return
    end

    schedules.each do |s|
      status = s.status.gsub('@', '')
      if status.nil? || status.length.zero?
        logger.warn "status was empty: id=#{s.id}"
        next
      end

      post status unless $DEBUG
      logger.info "posted #{s.status_id} #{status}"
    end

    Var[:last_id] = schedules.last.status_id unless $DEBUG
    logger.info "wrote last_id=#{schedules.last.status_id}"
  rescue Object => e
    bt = e.backtrace.join("\n")
    logger.error "#{e.class}:#{e.to_s} -- #{bt}"
  end
end


bot = MirakuiMetro.new
bot.logger.debug 'start'
bot.run
bot.logger.debug 'finished'


__END__