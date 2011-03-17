
require "rubygems"
require "reliable-msg/agent"

require "monitor"

module ReliableMsg::Agent #:nodoc:
  class Workers

    @@default_options = {
      :uri     => "druby://localhost:6438",
      :every   => 1.0,
      :target  => "queue.*",
      :threads => 1,
    }.freeze

    def initialize logger, options = {}
      @logger  = logger
      @options = options
      @locker  = Monitor.new
      @threads = nil
    end

    def start
      @locker.synchronize {
        raise AgentError, "workers already started." if alive?

        @logger.info { "starting workers." }

        threads = (t = @options[:threads].to_i) <= 0 ? 1 : t
        @threads = (1..threads).inject([]) { |t, i|
          t << Thread.fork { worker_loop }
        }
      }
    end

    def stop
      @locker.synchronize {
        raise AgentError, "workers already stopped." unless alive?

        @logger.info { "stopping workers." }

        @threads.each { |t| t[:dying] = true }
        @threads.each { |t| t.wakeup rescue nil }
        @threads.each { |t| t.join }
        @threads = nil
      }
    end

    def alive?
      @locker.synchronize { !! @threads }
    end

    private

    def worker_loop
      agent  = Agent.new @logger
      uri    = @options[:uri]    || @@default_options[:uri]
      every  = @options[:every]  || @@default_options[:every]
      target = @options[:target] || @@default_options[:target]

      until Thread.current[:dying]
        begin
          sleep every
          
          remote_qm = DRb::DRbObject.new_with_uri uri
          queue_name = remote_qm.stale_queue target
          next unless queue_name
  
          q = ReliableMsg::Queue.new queue_name, :drb_uri => uri
          q.get { |m|
            begin
              tx = Thread.current[ReliableMsg::Client::THREAD_CURRENT_TX]
              Thread.current[ReliableMsg::Client::THREAD_CURRENT_TX] = nil

              @logger.info { "message received - <#{m.id}>" }
              raise AgentError, "agent proc failed."  unless agent.call(m.dup)
            ensure
              Thread.current[ReliableMsg::Client::THREAD_CURRENT_TX] = tx
            end
          }
        rescue Exception => e
          @logger.warn { "error in fetch-msg/agent-proc: #{e}\n#{e.backtrace.join("\n\t")}" }
        end
      end
    end

  end
end

