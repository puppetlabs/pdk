if ENV.fetch('COVERAGE', nil) == 'yes'
  require 'codecov'
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console,
    SimpleCov::Formatter::Codecov,
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

    # do not track gitignored files
    # this adds about 4 seconds to the coverage check
    # this could definitely be optimized
    add_filter do |f|
      # system returns true if exit status is 0, which with git-check-ignore means file is ignored
      system("git check-ignore --quiet #{f.filename}")
    end
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'tempfile'

# automatically load any shared examples or contexts
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

analytics_config = nil

FIXTURES_DIR = File.join(__dir__, 'fixtures')
EMPTY_MODULE_ROOT = File.join(FIXTURES_DIR, 'module_root')

RSpec.shared_context 'stubbed logger' do
  let(:logger) { instance_double('PDK::Logger').as_null_object }

  before(:each) do |example|
    allow(PDK).to receive(:logger).and_return(logger) if example.metadata[:use_stubbed_logger]
  end
end

RSpec.shared_context 'stubbed analytics' do
  let(:analytics) { PDK::Analytics::Client::Noop.new(logger: logger) }

  before(:each) do |example|
    allow(PDK).to receive(:analytics).and_return(analytics) if example.metadata[:use_stubbed_analytics]
  end
end

RSpec.configure do |c|
  c.define_derived_metadata do |metadata|
    metadata[:use_stubbed_logger] = true unless metadata.key?(:use_stubbed_logger)
    metadata[:use_stubbed_analytics] = true unless metadata.key?(:use_stubbed_analytics)
  end

  c.include_context 'stubbed logger'
  c.include_context 'stubbed analytics'

  c.before(:suite) do
    require 'yaml'
    analytics_config = Tempfile.new('analytics.yml')
    analytics_config.write(YAML.dump(disabled: true))
    analytics_config.close
    ENV['PDK_ANALYTICS_CONFIG'] = analytics_config.path
  end

  c.after(:suite) do
    analytics_config.unlink
  end

  # This should catch any tests where we are not mocking out the actual calls to Rubygems.org
  c.before(:each) do
    allow(Gem::SpecFetcher).to receive(:fetcher).and_raise('Unmocked call to Gem::SpecFetcher.fetcher!')
    ENV['PDK_DISABLE_ANALYTICS'] = 'true'
  end

  c.add_setting :root
  c.root = File.dirname(__FILE__)
end

# Add method to StringIO needed for TTY::Prompt::Test to work on tty-prompt >=
# 0.19 (see https://github.com/piotrmurach/tty-prompt/issues/104)
class StringIO
  def wait_readable(*)
    true
  end
end

module OS
  def self.windows?
    (%r{cygwin|mswin|mingw|bccwin|wince|emx} =~ RUBY_PLATFORM) != nil
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
