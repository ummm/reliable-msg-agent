
require "rubygems"
require "reliable-msg"

module ReliableMsg #:nodoc:
  module Agent #:nodoc:
    autoload :Version   , "reliable-msg/agent/version"
    autoload :AgentError, "reliable-msg/agent/error"
    autoload :Service   , "reliable-msg/agent/service"
    autoload :Workers   , "reliable-msg/agent/workers"
    autoload :Agent     , "reliable-msg/agent/agent"
  end
end

