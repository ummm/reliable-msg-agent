
require File.dirname(__FILE__) + "/spec_helper.rb"

require "logger"

describe ReliableMsg::Agent::Service do
  before do
    l = Logger.new(nil)
    @s = ReliableMsg::Agent::Service.new l
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

