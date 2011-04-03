
require File.dirname(__FILE__) + "/spec_helper.rb"

require "logger"

describe ReliableMsg::Agent::Service do
  before do
    @times_of_start_stop = 30

    @logger = Logger.new(nil)
    @conf = {
      "foo" => "bar",
      "baz" => "qux",
      "consumers" => [
        {
          "source_uri" => "druby://localhost:6438",
          "target"     => "queue.*",
          "every"      => 1.0,
          "threads"    => 1,
        },
      ],
    }
  end

  describe "When initialize" do
    before do
      @s = ReliableMsg::Agent::Service.new @logger, @conf
    end

    it "should be able to #start" do
      @s.start
    end
  
    it "should not be able to #stop" do
      Proc.new {
       @s.stop
      }.should raise_error ReliableMsg::Agent::AgentError
    end
  
    it "should not be alive" do
      @s.alive?.should_not be_true
    end
  
    describe "When started" do
      before do
        @s.start
      end
  
      it "should not be able to #start" do
        Proc.new {
          @s.start
        }.should raise_error ReliableMsg::Agent::AgentError
      end
    
      it "should be able to #stop" do
       @s.stop
      end
  
      it "should be alive" do
        @s.alive?.should be_true
      end
  
    end
  
    it "should be able to #start > #stop > #start > ..." do
      @times_of_start_stop.times {
        @s.start
        @s.stop
      }
    end
  
    after do
      @s.stop rescue nil
      @s = nil
    end
  end

  describe "When replace the mock classes depend Service" do
    before do
      @consumers = mock ReliableMsg::Agent::Consumers
      @consumers.stub!(:new).and_return @consumers
  
      consumers_alive = false
      @consumers.stub!(:start) { consumers_alive = true }
      @consumers.stub!(:stop) { consumers_alive = false }
      @consumers.stub!(:alive?).and_return { consumers_alive }

      ReliableMsg::Agent::Service.class_eval {
        public_class_method :dependency_classes
        public_class_method :dependency_classes_init
      }
      ReliableMsg::Agent::Service.dependency_classes[:Consumers] = @consumers
    end
  
    describe "When initialize" do
      it "mockclass should receive #new(@logger, @conf['consumers']) exactly 1" do
        @consumers.should_receive(:new).
          with(@logger, @conf["consumers"]).
          exactly(1)
        ReliableMsg::Agent::Service.new @logger, @conf
      end

      describe "#start" do
        before do
          @s = ReliableMsg::Agent::Service.new @logger, @conf
        end

        it "mockclass should receive #start exactly 1" do
          @consumers.should_receive(:start).with(no_args).exactly(1)
          @s.start
        end

        after do
          @s.stop rescue nil
          @s = nil
        end
      end
    end
  
    after do
      ReliableMsg::Agent::Service.dependency_classes_init
    end
  end
end

