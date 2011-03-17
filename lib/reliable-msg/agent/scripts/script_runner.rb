
require "rubygems"
require "reliable-msg/agent"

require "erb"
require "logger"
require "yaml"
require "fileutils"
require "timeout"
require "etc"

module ReliableMsg::Agent #:nodoc:
  class ScriptRunner #:nodoc:

    def start options = {}
      $stderr.puts "*** Starting ReliableMsg-Agent..."

      default_options = {
        :verbose => false,
        :conf => "/etc/reliable-msg-agent/agent.conf",
        :log => "/var/reliable-msg-agent/agent.log",
        :pid => "/var/reliable-msg-agent/agent.pid",
      }
      opt = default_options.merge options
      
      conf = load_configurations opt[:conf]
      change_privilege conf
      pidfile_accessible_test opt[:pid]
      logger = create_logger conf["logger"], opt[:log]

      agent_definition conf["agent"]

      daemonize(logger) {
        service = Service.new logger, conf
  
        register_signal_handler logger, service, opt[:pid]
  
        service.start
        write_pidfile opt[:pid]
        while service.alive?; sleep 3; end
      }

    rescue Exception => e
      $stderr.puts "--- ReliableMsg-Agent error! - #{e.message}"
      $stderr.puts e.backtrace.join("\n\t") if opt[:verbose]
      exit 1

    ensure
      $stderr.puts "*** done."
    end

    def stop options = {}
      $stderr.puts "*** Stopping ReliableMsg-Agent..."

      default_options = {
        :verbose => false,
        :pid => "/var/reliable-msg-agent/agent.pid",
      }
      opt = default_options.merge options

      # send signal
      pid = File.open(opt[:pid], "r") { |f| f.read }.to_i
      Process.kill :TERM, pid

      # wait
      timeout(10.0) { Process.waitpid pid rescue nil }

    rescue Exception => e
      $stderr.puts "--- ReliableMsg-Agent error! - #{e.message}"
      $stderr.puts e.backtrace.join("\n\t") if opt[:verbose]
      exit 1

    ensure
      $stderr.puts "*** done."
    end

    private

    def load_configurations conffile
      YAML.load(ERB.new(IO.read(conffile)).result)
    end

    def change_privilege conf
      user  = conf["user"]
      uid   = begin
                Etc.getpwnam(user.to_s).uid
              rescue ArgumentError
                raise "can't find user for #{user}"
              end
      group = conf["group"]
      gid   = begin
                Etc.getgrnam(group.to_s).gid
              rescue ArgumentError
                raise "can't find group for #{group}"
              end

      raise "Dont't run as root user." if uid == 0

      Process::Sys.setegid(gid)
      Process::Sys.seteuid(uid)
    end

    def pidfile_accessible_test pid
      raise "PID file already exists - #{pid}" if File.exist?(pid)
      FileUtils.touch pid; File.unlink pid
    end

    def create_logger creation_procedure, logfile
      if creation_procedure
        eval(creation_procedure.to_s).call(logfile)
      else
        Logger.new(logfile)
      end
    end

    def daemonize logger
      fork {
        Process.setsid
        fork {
          begin
            Dir.chdir("/")
            $stdin.reopen  "/dev/null", "r"
            $stdout.reopen "/dev/null", "a"
            $stderr.reopen "/dev/null", "a"

            yield
            sleep

          rescue Exception => e
            logger.fatal { "ReliableMsg-Agent error! - #{e.message}" }
            logger.fatal { e.backtrace.join("\n\t") }
            exit! 1
          end
        }
      }
    end

    def register_signal_handler logger, service, pidfile
      stopping = false
      [:TERM].each { |sig|
        Signal.trap(sig) {
          unless stopping
            begin
              stopping = true
              service.stop
              File.unlink pidfile if File.exist? pidfile
              exit! 0

            rescue Exception => e
              File.unlink pidfile if File.exist? pidfile
              logger.fatal { "ReliableMsg-Agent error! - #{e.message}" }
              logger.fatal { e.backtrace.join("\n\t") }
              exit! 1
            end
          end
        }
      }
    end

    def write_pidfile pidfile
      File.open(pidfile, "w") { |f| f.puts $$ }
    end

    def agent_definition deffile
      Agent.class_eval open(deffile, "r") { |f| f.read }
    end

  end
end

