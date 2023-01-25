require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::NtfyAgent do
  before(:each) do
    @valid_options = Agents::NtfyAgent.new.default_options
    @checker = Agents::NtfyAgent.new(:name => "NtfyAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
