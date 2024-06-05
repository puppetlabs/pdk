require 'fileutils'
require 'serverspec'
require 'tmpdir'
require 'open3'
require 'pdk/generate/module'
require 'pdk/util/template_uri'
require 'tempfile'
require 'json'

# Sets default puppet/ruby versions to be used within the tests
PDK_VERSION = {
  latest: {
    full: '8.6.0',
    major: '8',
    ruby: '3.2.3'
  },
  lts: {
    full: '7.30.0',
    major: '7',
    ruby: '2.7.8'
  }
}.freeze

# automatically load any shared examples or contexts
Dir['./spec/acceptance/support/**/*.rb'].sort.each { |f| require f }

if Gem.win_platform?
  set :backend, :cmd
else
  set :backend, :exec
end

# The default directory pdk bin would be installed to on this machine
def default_installed_bin_dir
  if Gem.win_platform?
    # TODO: Also support Windows without cygwin
    '/cygdrive/c/Program\ Files/Puppet\ Labs/DevelopmentKit/bin'
  else
    '/opt/puppetlabs/bin'
  end
end

# This method allows a block to be passed in and if an exception is raised
# that matches the 'error_matcher' matcher, the block will wait a set number
# of seconds before retrying.
# Params:
# - max_retry_count - Max number of retries
# - retry_wait_interval_secs - Number of seconds to wait before retry
# - error_matcher - Matcher which the exception raised must match to allow retry
# Example Usage:
# retry_on_error_matching(3, 5, /OpenGPG Error/) do
#   apply_manifest(pp, :catch_failures => true)
# end
def retry_on_error_matching(max_retry_count = 3, retry_wait_interval_secs = 5, error_matcher = nil)
  try = 0
  begin
    try += 1
    yield
  rescue StandardError => e
    raise unless try < max_retry_count && (error_matcher.nil? || e.message =~ error_matcher)

    sleep retry_wait_interval_secs
    retry
  end
end

module Specinfra
  module Backend
    class Cmd
      def execute_script(script)
        if Open3.respond_to?(:capture3)
          stdout, stderr, status = Open3.capture3(script)
          { stdout: stdout, stderr: stderr, status: status }
        else
          stdout = `#{script} 2>&1`
          { stdout: stdout, stderr: nil, status: $? } # rubocop:disable Style/SpecialGlobalVars
        end
      end
    end
  end
end

tempdir = nil

# TODO: --path is deprecated
# bundler won't install bundler into the --path, so in order to access ::Bundler.with_unbundled_env
# from within pdk during spec tests, we have to manually re-add the global gem path :(
bundler_spec = Gem::Specification.find_by_name('bundler')
bundler_path = bundler_spec.gem_dir
ENV['GEM_PATH'] = [ENV.fetch('GEM_PATH', nil), File.absolute_path(File.join(bundler_path, '..', '..')).to_s].compact.join(File::PATH_SEPARATOR)

# Save bundle environment from being purged by specinfra. This needs to be repeated for every example, as specinfra does not correctly reset the environment after a `describe command()` block
# presumably https://github.com/mizzy/specinfra/blob/79b62b37909545b67b7492574a97c300fb1dc91e/lib/specinfra/backend/exec.rb#L143-L165
bundler_env = {}
keys = ['BUNDLER_EDITOR', 'BUNDLE_BIN_PATH', 'BUNDLE_GEMFILE', 'RUBYOPT', 'GEM_HOME', 'GEM_PATH', 'GEM_CACHE']
keys.each do |k|
  bundler_env[k] = ENV.fetch(k, nil) if ENV.key? k
end

# dup to avoid pollution from specinfra
Specinfra.configuration.env = bundler_env.dup

RSpec.configure do |c|
  c.before(:suite) do
    RSpec.configuration.template_dir = Dir.mktmpdir
    output, status = Open3.capture2e('git', 'clone', '--bare', PDK::Util::TemplateURI.default_template_uri, RSpec.configuration.template_dir)
    raise "Failed to cache module template: #{output}" unless status.success?

    tempdir = Dir.mktmpdir
    Dir.chdir(tempdir)
    puts "Working in #{tempdir}"

    # Remove PUPPET_GEM_VERSION if it exists in the test environment
    ENV.delete('PUPPET_GEM_VERSION')
  end

  c.after(:suite) do
    Dir.chdir('/')
    FileUtils.rm_rf(tempdir)
    FileUtils.rm_rf(RSpec.configuration.template_dir)
    puts "Cleaned #{tempdir}"
  end

  c.after do |e|
    # Dump stderr into error message to help with debugging if test failed
    e.exception.message << "\nDumping stderr output:\n\n#{subject.stderr}\n" if e.exception && (subject.respond_to?(:stderr) && subject.stderr != '')

    # recover bundle environment from serverspec munging
    bundler_env.each_key do |k|
      ENV[k] = bundler_env[k]
    end
  end

  c.expect_with(:rspec) do |e|
    e.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  c.add_setting :fixtures_path, default: File.join(File.dirname(__FILE__), 'fixtures')
  c.add_setting :template_dir
  c.profile_examples = true
end
