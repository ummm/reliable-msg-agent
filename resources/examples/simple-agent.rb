
# this script is evaluated by the context of ReliableMsg::Agnet::Agent class.

require "yaml"

#
# The method of processing the message is defined.
#
# if the evaluation result is nil or false,
# it is considered that it failes.
#
# === Args
#
# +msg+     :: fetched message from reliable-msg queue.
# +options+ :: the options (it is still unused.)
#
def call msg, options = {}
  @logger.info { "message received\n#{msg.to_yaml}" }
end

