if ENV.fetch('COVERAGE', nil) == 'yes'
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ]

  SimpleCov.start do
    track_files 'lib/**/*.rb'

    add_filter '/spec'

    # do not track vendored files
    add_filter '/lib/pdk/util/windows'
    add_filter '/vendor'
    add_filter '/.vendor'
    add_filter '/docs'
    add_filter '/lib/pdk/version.rb'
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'tempfile'

# automatically load any shared examples or contexts
Dir['./spec/support/**/*.rb'].each { |f| require f }

FIXTURES_DIR = File.join(__dir__, 'fixtures')
EMPTY_MODULE_ROOT = File.join(FIXTURES_DIR, 'module_root')

RSpec.shared_context 'stubbed logger' do
  let(:logger) { instance_double(PDK::Logger).as_null_object }

  before do |example|
    allow(PDK).to receive(:logger).and_return(logger) if example.metadata[:use_stubbed_logger]
  end
end

RSpec.configure do |c|
  c.define_derived_metadata do |metadata|
    metadata[:use_stubbed_logger] = true unless metadata.key?(:use_stubbed_logger)
  end

  c.include_context 'stubbed logger'

  c.before(:suite) do
    require 'yaml'
  end

  # This should catch any tests where we are not mocking out the actual calls to Rubygems.org
  c.before do
    allow(Gem::SpecFetcher).to receive(:fetcher).and_raise('Unmocked call to Gem::SpecFetcher.fetcher!')
  end

  c.add_setting :root
  c.root = File.dirname(__FILE__)
end

# Sets default puppet/ruby versions to be used within the tests
# Duplicates of this are found within spec_helper_package.rb and spec_helper_acceptance.rb and should be updated simultaneously.
PDK_VERSION = {
  latest: {
    full: '8.6.0',
    major: '8',
    ruby: '3.2.*'
  },
  lts: {
    full: '8.6.0',
    major: '8',
    ruby: '3.2.*'
  }
}.freeze

# Add method to StringIO needed for TTY::Prompt::Test to work on tty-prompt >=
# 0.19 (see https://github.com/piotrmurach/tty-prompt/issues/104)
class StringIO
  def wait_readable(*)
    true
  end
end

module OS
  def self.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end

  def self.mac?
    RUBY_PLATFORM.include?('darwin') != nil
  end

  def self.unix?
    !OS.windows?
  end

  def self.linux?
    OS.unix? && !OS.mac?
  end
end
