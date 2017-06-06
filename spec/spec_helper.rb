$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pdk'
require 'pdk/cli'

RSpec.shared_context :stubbed_logger do
  let(:logger) { instance_double('PDK::Logger').as_null_object }

  before(:each) { allow(PDK).to receive(:logger).and_return(logger) }
end

RSpec.configure do |c|
  c.include_context :stubbed_logger
end
