
require "rubygems"
require "reliable-msg/agent"

require "monitor"

module ReliableMsg::Agent #:nodoc:
  class Consumers

    @@default_options = {
      "source_uri" => "druby://localhost:6438",
      "target"     => "queue.*",
      "every"      => 1.0,
      "threads"    => 1,
    }.freeze

    def initialize logger, options
      @logger  = logger
      @options = options
      raise AgentError, "no configuration specified."  unless @options
      @locker  = Monitor.new
      @threads = nil
    end

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

    def alive?; @locker.synchronize { !! @threads }; end

    private

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

    def connect_qm qm, target, uri, every
      error_raised = false
      begin
        queue_name = qm.stale_queue target
        @logger.warn { "Connect to #{uri} successfully at #{Time.now}" } if error_raised
        return queue_name

      rescue => e
        @logger.warn { "Lost connection to #{uri} at #{Time.now} - #{e.message}" } unless error_raised
        error_raised = true
        sleep every
        return nil if Thread.current[:dying]
        retry
      end
    end

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

