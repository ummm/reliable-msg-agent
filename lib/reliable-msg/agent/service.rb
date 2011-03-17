
require "rubygems"
require "reliable-msg/agent"

require "monitor"

module ReliableMsg::Agent #:nodoc:
  class Service
    def initialize logger, options = {}
      @logger  = logger
      @options = options

      @workers = Workers.new @logger, @options
      @locker = Monitor.new
    end

    def start
      @locker.synchronize {
        raise AgentError, "service already started." if alive?

        @logger.info { "reliable-msg agent service starting..." }
        @workers.start
        @logger.info { "reliable-msg agent service started." }
      }
    end

    def stop
      @locker.synchronize {
        raise AgentError, "service already stopped." unless alive?

        @logger.info { "reliable-msg agent service stopping..." }
        @workers.stop
        @logger.info { "reliable-msg agent service stopped." }
      }
    end

    def alive?
      @locker.synchronize {
        !! @workers.alive?
      }
    end
  end
end

