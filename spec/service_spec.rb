
require File.dirname(__FILE__) + "/spec_helper.rb"

require "logger"

describe ReliableMsg::Agent::Service do
  before do
    logger = Logger.new(nil)
    conf = {
      "consumers" => [
        {
          "source_uri" => "druby://localhost:6438",
          "target"     => "queue.*",
          "every"      => 1.0,
          "threads"    => 1,
        },
      ],
    }
    @s = ReliableMsg::Agent::Service.new logger, conf
  end

  it "should be able to #start" do
    @s.start
  end

  it "should not be alive" do
    @s.alive?.should_not be_true
  end

  describe "When started" do
    before do
      @s.start
    end

    it "should be alive" do
      @s.alive?.should be_true
    end

  end

  after do
    @s.stop rescue nil
    @s = nil
  end
end

