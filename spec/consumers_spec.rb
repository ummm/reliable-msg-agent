
require File.dirname(__FILE__) + "/spec_helper.rb"

require "logger"

describe ReliableMsg::Agent::Consumers do
  before do
    logger = Logger.new(nil)
    conf = [
      {
        "source_uri" => "druby://localhost:6438",
        "target"     => "queue.*",
        "every"      => 1.0,
        "threads"    => 1,
        "modify_rules" => {
          "url" => "Proc.new { |url| url.host = '127.0.0.1'; url.port = 80; url }",
        },
        "http" => {
          "timeout" => 60,
        }
      },
    ]
    @w = ReliableMsg::Agent::Consumers.new logger, conf
  end

  it "should be able to #start" do
    @w.start
  end

  it "should not be alive" do
    @w.alive?.should_not be_true
  end

  describe "When started" do
    before do
      @w.start
    end

    it "should be alive" do
      @w.alive?.should be_true
    end

  end

  after do
    @w.stop rescue nil
    @w = nil
  end
end

