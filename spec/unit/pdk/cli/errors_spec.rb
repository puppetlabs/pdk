require 'spec_helper'

describe 'PDK FatalError' do
  subject(:fatal_error) { PDK::CLI::FatalError }

  it 'has a message' do
    error = fatal_error.new
    expect(error.message).not_to be_nil
  end
end
