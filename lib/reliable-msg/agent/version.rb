
require "rubygems"
require "reliable-msg/agent"

module ReliableMsg::Agent #:nodoc:
  module Version #:nodoc:
    unless defined? MAJOR
      MAJOR  = 0
      MINOR  = 1
      TINY   = 0
      PRE    = nil

      STRING = [MAJOR, MINOR, TINY, PRE].compact.join(".")
    end
  end
end

