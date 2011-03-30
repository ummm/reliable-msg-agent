
require "rubygems"
require "reliable-msg/agent"

require "monitor"

module ReliableMsg::Agent #:nodoc:

  # Class of consumers for reliable-msg queue massaging.
  #
  # It has the function to make the agent acquire the message
  # from ReliableMsg-Queue of the object and execute processing. 
  #
  class Consumers

    @@default_options = {
      "source_uri" => "druby://localhost:6438",
      "target"     => "queue.agent",
      "every"      => 1.0,
      "threads"    => 1,
    }.freeze

    # Initialize.
    #
    # === Args
    #
    # +logger+  :: the logger.
    # +options+ :: consumers options.
    #
    # valid options for +options+ are:
    #
    # +source_uri+ :: uri for source reliable-msg queue.
    # +target+     :: target queue name for source reliable-msg queue.
    # +every+      :: interval seconds when connection fails
    # +threads+    :: times for consumer threads.
    #
    def initialize logger, options
      @logger  = logger
      @options = options
      raise AgentError, "no configuration specified."  unless @options
      @locker  = Monitor.new
      @threads = nil
    end

    # Start consumers.
    #
    def start
      @locker.synchronize {
        raise AgentError, "workers already started." if alive?

        @logger.info { "--- starting workers." }

        @threads = []
        @options.each { |opts|
          conf = @@default_options.merge(opts || {})
          conf["threads"].to_i.times {
            @threads << Thread.fork(conf) { |c| consuming_loop(c) }
          }
        }
      }
    end

    # Stop consumers.
    #
    def stop
      @locker.synchronize {
        raise AgentError, "workers already stopped." unless alive?

        @logger.info { "--- stopping workers." }

        @threads.each { |t| t[:dying] = true }
        @threads.each { |t| t.wakeup rescue nil } # for immediate stop
        @threads.each { |t| t.join }
        @threads = nil
      }
    end

    # Return the state of alive or not alive.
    #
    def alive?; @locker.synchronize { !! @threads }; end

    private

    # Loop for consumer.
    #
    # === Args
    #
    # +conf+:: consumer configurations.
    #
    def consuming_loop conf
      agent = Agent.new @logger
      uri, every, target = conf["source_uri"], conf["every"], conf["target"]

      until Thread.current[:dying]
        begin
          remote_qm = DRb::DRbObject.new_with_uri uri

          queue_name = connect_qm(remote_qm, target, uri, every)
          next unless queue_name

          fetch(queue_name, uri) { |m|
            raise AgentError, "agent proc failed." unless agent.call(m, conf)
          }

        rescue Exception => e
          @logger.warn { "error in fetch-msg/agent-proc: #{e}\n#{e.backtrace.join("\n\t")}" }
        end

        sleep every
      end
    end

    # Test for connect to reliable-msg queue manager.
    # Returns valid queue-name.
    #
    # === Args
    #
    # +qm+     :: the queue manager.
    # +target+ :: target queue name for source reliable-msg queue.
    # +uri+    :: uri for source reliable-msg queue.
    # +every+  :: interval seconds when connection fails
    #
    def connect_qm qm, target, uri, every
      error_raised = false
      begin
        raise "queue-manager is not alive." unless qm.alive?
        @logger.warn { "Connect to #{uri} successfully at #{Time.now}" } if error_raised
        return target

      rescue => e
        @logger.warn { "Lost connection to #{uri} at #{Time.now} - #{e.message}" } unless error_raised
        error_raised = true
        sleep every
        return nil if Thread.current[:dying]
        retry
      end
    end

    # Fetch message from reliable-msg queue.
    # Return evaluation result of yield.
    #
    # === Args
    #
    # +queue_name+ :: queue name for source reliable-msg queue.
    # +source_uri+ :: uri for source reliable-msg queue.
    #
    def fetch queue_name, source_uri
      ReliableMsg::Queue.new(queue_name, :drb_uri => source_uri).get { |m|
        begin
          tx = Thread.current[ReliableMsg::Client::THREAD_CURRENT_TX]
          Thread.current[ReliableMsg::Client::THREAD_CURRENT_TX] = nil

          @logger.info { "message fetched - <#{m.id}>" }
          yield m

        ensure
          Thread.current[ReliableMsg::Client::THREAD_CURRENT_TX] = tx
        end
      }
    end

  end
end

