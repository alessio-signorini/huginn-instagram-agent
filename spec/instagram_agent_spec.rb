require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::InstagramAgent do
  before(:each) do
    @valid_options = Agents::InstagramAgent.new.default_options
    @checker = Agents::InstagramAgent.new(:name => "InstagramAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
