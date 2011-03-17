
require File.dirname(__FILE__) + "/spec_helper.rb"

require "logger"

describe ReliableMsg::Agent::Workers do
  before do
    l = Logger.new(nil)
    @w = ReliableMsg::Agent::Workers.new l
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

