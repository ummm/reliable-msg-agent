
require "rubygems"
require "reliable-msg"

module ReliableMsg #:nodoc:
  module Agent #:nodoc:
    autoload :Agent     , "reliable-msg/agent/agent"
    autoload :AgentError, "reliable-msg/agent/error"
    autoload :Consumers , "reliable-msg/agent/consumers"
    autoload :Service   , "reliable-msg/agent/service"
    autoload :Version   , "reliable-msg/agent/version"
  end
end

