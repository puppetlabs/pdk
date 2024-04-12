require 'beaker-rspec'
require 'beaker-puppet'

Dir['./spec/package/support/*.rb'].sort.each { |f| require f }

include SpecUtils # rubocop:disable Style/MixinUsage

bin_path = SpecUtils.windows_node? ? 'bin$PATH' : 'bin:$PATH'
set :path, "#{SpecUtils.install_dir}/#{bin_path}"

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
