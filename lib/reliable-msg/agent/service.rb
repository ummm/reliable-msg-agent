
require "rubygems"
require "reliable-msg/agent"

require "monitor"

module ReliableMsg::Agent #:nodoc:

  # Class of ReliableMsg-Agent service
  #
  class Service

    # Initialilze.
    #
    # === Args
    #
    # +logger+  :: the logger.
    # +options+ :: service options.
    #
    def initialize logger, options = {}
      @logger  = logger
      @options = options

      @consumers = @@dependency_classes[:Consumers].new @logger, @options["consumers"]
      @locker = Monitor.new
    end

    # Start service.
    #
    def start
      @locker.synchronize {
        raise AgentError, "service already started." if alive?

        @logger.info { "*** reliable-msg agent service starting..." }
        @consumers.start
        @logger.info { "*** reliable-msg agent service started." }
      }
    end

    # Stop service.
    #
    def stop
      @locker.synchronize {
        raise AgentError, "service already stopped." unless alive?

        @logger.info { "*** reliable-msg agent service stopping..." }
        @consumers.stop
        @logger.info { "*** reliable-msg agent service stopped." }
      }
    end

    # Return the state of alive or not alive.
    #
    def alive?
      @locker.synchronize {
        !! @consumers.alive?
      }
    end

    # For testcase. To replace the class for which Service depends with Mock.
    #
    # === Example
    #
    #   # Change method scope.
    #   Service.class_eval {
    #     public_class_method :dependency_classes
    #     public_class_method :dependency_classes_init
    #   }
    #
    #   # Consumers is replaced with ConsumersMock.
    #   Service.dependency_classes[:Consumers] = ConsumersMock
    #
    #   # test code that uses ConsumersMock...
    #   test_foo
    #   test_bar
    #
    #   # re-init.
    #   Service.dependency_classes_init
    #
    def self.dependency_classes
      @@dependency_classes
    end
    private_class_method :dependency_classes
    
    # For testcase. Dependency classes is initialized.
    #
    def self.dependency_classes_init
      @@dependency_classes = {
        :Consumers => Consumers,
      }
    end
    private_class_method :dependency_classes_init
    dependency_classes_init

  end
end

