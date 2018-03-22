# frozen_string_literal: true

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
    track_files 'lib/**/*.rb'

    add_filter '/spec'

    # do not track vendored files
    add_filter '/lib/puppet'
    add_filter '/vendor'
    add_filter '/.vendor'

    # do not track gitignored files
    # this adds about 4 seconds to the coverage check
    # this could definitely be optimized
    add_filter do |f|
      # system returns true if exit status is 0, which with git-check-ignore means file is ignored
      system("git check-ignore --quiet #{f.filename}")
    end
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
