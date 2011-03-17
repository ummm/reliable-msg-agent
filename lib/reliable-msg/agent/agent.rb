
require "rubygems"
require "reliable-msg/agent"

module ReliableMsg::Agent #:nodoc:
  class Agent
    def initialize logger
      @logger = logger
    end
 
    def call msg, options = {}
      raise AgentError, "#call(msg,options={}) not implemented!"
    end   
  end
end

