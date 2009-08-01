require 'logger'

module Gena

  class Loggable

    def logger
      unless defined? @logger
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
      end
      @logger
    end

    def logger=(logger)
      @logger = logger
    end

  end

end
