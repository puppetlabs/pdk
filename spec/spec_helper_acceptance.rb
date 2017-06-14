require 'fileutils'
require 'serverspec'
require 'tmpdir'

if Gem.win_platform?
  set :backend, :cmd
else
  set :backend, :exec
end

tempdir = nil

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
    tempdir = Dir.mktmpdir
    Dir.chdir(tempdir)
    puts "Working in #{tempdir}"
  end
  c.after(:suite) do
    Dir.chdir('/')
    FileUtils.rm_rf(tempdir)
    puts "Cleaned #{tempdir}"
  end

  c.after(:each) do
    # recover bundle environment from serverspec munging
    bundler_env.keys.each do |k|
      ENV[k] = bundler_env[k]
    end
  end
end
