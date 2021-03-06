
require "rubygems"
require "reliable-msg/agent"

require "yaml"

module ReliableMsg::Agent #:nodoc:
  class Agent
    def initialize logger
      @logger = logger
    end
 
    # The method of processing the message is defined.
    #
    # if the evaluation result is nil or false,
    # it is considered that it failes.
    #
    # === Args
    #
    # +msg+     :: fetched message from reliable-msg queue.
    # +conf+    :: consumer configurations.
    # +options+ :: the options (it is still unused.)
    #
    def call msg, conf, options = {}
      @logger.info { "message received\n#{msg.to_yaml}" }
    end   
  end
end

