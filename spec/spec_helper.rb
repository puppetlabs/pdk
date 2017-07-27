if ENV['COVERAGE'] == 'yes'
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter '/spec/'
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pdk'
require 'pdk/cli'

# automatically load any shared examples or contexts
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.shared_context :stubbed_logger do
  let(:logger) { instance_double('PDK::Logger').as_null_object }

  before(:each) { allow(PDK).to receive(:logger).and_return(logger) }
end

RSpec.configure do |c|
  c.include_context :stubbed_logger
end

RSpec.shared_context :validators do
  let(:validators) do
    [
      PDK::Validate::MetadataValidator,
      PDK::Validate::PuppetValidator,
      PDK::Validate::RubyValidator,
    ]
  end
end
