require 'beaker-rspec'
require 'beaker-puppet'

Dir['./spec/package/support/*.rb'].sort.each { |f| require f }

include SpecUtils # rubocop:disable Style/MixinUsage

bin_path = SpecUtils.windows_node? ? 'bin$PATH' : 'bin:$PATH'
set :path, "#{SpecUtils.install_dir}/#{bin_path}"

# IMPORTANT: The following block should be updated with the version of ruby that is included within the newest
#   Puppet release for each major version. If you are running integration testing prior to a release and its
#   failing, verify that the following versions are correct.
# Duplicates of this are found within spec_helper.rb and spec_helper_acceptance.rb and should be updated simultaneously.
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

RSpec.configure do |c|
  c.include SpecUtils
  c.extend SpecUtils

  c.before(:suite) do
    hosts.each do |host|
      PackageHelpers.install_pdk_on(host)
    end
  end

  # rubocop:disable RSpec/BeforeAfterAll
  c.before(:all) do
    RSpec.configuration.logger.log_level = :warn
  end

  c.after(:all) do
    RSpec.configuration.logger.log_level = :verbose
  end
  # rubocop:enable RSpec/BeforeAfterAll

  c.after do
    cmd = if windows_node?
            command('rm -Recurse -Force $env:LOCALAPPDATA/PDK/Cache/ruby')
          else
            command('rm -rf ~/.pdk/cache/ruby')
          end

    # clear out any cached gems
    cmd.run
  end
end
