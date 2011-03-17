
# this script is evaluated by the context of ReliableMsg::Agnet::Agent class.

require "yaml"
require "ap4r"

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

  # The following codes use the mechanism of sending the message by ap4r.
  conf = {
    "modify_rules" => {
      "url" => " Proc.new { |url| url.host = '127.0.0.1'; url } ",
    },
    "http" => {
      "timeout" => 60,
    },
  }
  dispatcher = Ap4r::Dispatchers.new nil, conf, @logger

  @logger.debug { "dispatcher get message\n#{msg.to_yaml}" }
  response = dispatcher.send(:get_dispather_instance,
                             msg.headers[:dispatch_mode],
                             msg,
                             conf).call
  @logger.debug { "dispatcher get response\n#{response.to_yaml}" }

end

