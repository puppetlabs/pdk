if ENV['COVERAGE'] == 'yes'
  require 'coveralls'
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console,
    Coveralls::SimpleCov::Formatter,
  ]
  SimpleCov.start do
    add_filter '/spec'
    # do not track vendored files
    add_filter '/vendor'
    add_filter '/.vendor'
  end
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pdk'
require 'pdk/cli'

# automatically load any shared examples or contexts
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.shared_context :stubbed_logger do
  let(:logger) { instance_double('PDK::Logger').as_null_object }

  before(:each) do |example|
    allow(PDK).to receive(:logger).and_return(logger) if example.metadata[:use_stubbed_logger]
  end
end

RSpec.configure do |c|
  c.define_derived_metadata do |metadata|
    metadata[:use_stubbed_logger] = true unless metadata.key?(:use_stubbed_logger)
  end

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
