require 'fileutils'
require 'serverspec'
require 'tmpdir'
require 'rspec/xsd'
require 'open3'
require 'pdk/generate/module'
require 'pdk/util/ruby_version'

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

# bundler won't install bundler into the --path, so in order to access ::Bundler.with_clean_env
# from within pdk during spec tests, we have to manually re-add the global gem path :(
pdk_ruby_version = PDK::Util::RubyVersion.new
ENV['GEM_PATH'] = [(ENV['GEM_PATH'].empty? ? nil : ENV['GEM_PATH']), pdk_ruby_version.gem_path].compact.join(File::PATH_SEPARATOR)

# Save bundle environment from being purged by specinfra. This needs to be repeated for every example, as specinfra does not correctly reset the environment after a `describe command()` block
# presumably https://github.com/mizzy/specinfra/blob/79b62b37909545b67b7492574a97c300fb1dc91e/lib/specinfra/backend/exec.rb#L143-L165
bundler_env = {}
keys = %w[BUNDLER_EDITOR BUNDLE_BIN_PATH BUNDLE_GEMFILE
          RUBYOPT GEM_HOME GEM_PATH GEM_CACHE]
keys.each do |k|
  bundler_env[k] = ENV[k] if ENV.key? k
end

# dup to avoid pollution from specinfra
Specinfra.configuration.env = bundler_env.dup

RSpec.configure do |c|
  c.before(:suite) do
    RSpec.configuration.template_dir = Dir.mktmpdir
    output, status = Open3.capture2e('git', 'clone', '--bare', PDK::Util.default_template_url, RSpec.configuration.template_dir)
    raise "Failed to cache module template: #{output}" unless status.success?

    tempdir = Dir.mktmpdir
    Dir.chdir(tempdir)
    puts "Working in #{tempdir}"
  end

  c.after(:suite) do
    Dir.chdir('/')
    FileUtils.rm_rf(tempdir)
    FileUtils.rm_rf(RSpec.configuration.template_dir)
    puts "Cleaned #{tempdir}"
  end

  c.after(:each) do
    # recover bundle environment from serverspec munging
    bundler_env.keys.each do |k|
      ENV[k] = bundler_env[k]
    end
  end

  c.expect_with(:rspec) do |e|
    e.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  c.include RSpec::XSD
  c.add_setting :fixtures_path, default: File.join(File.dirname(__FILE__), 'fixtures')
  c.add_setting :template_dir
end
