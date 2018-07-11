require 'beaker-rspec'

Dir['./spec/package/support/*.rb'].sort.each { |f| require f }

RSpec.shared_context :set_path do
  let(:path) { windows_node? ? nil : "#{install_dir}/bin:$PATH" }
end

RSpec.configure do |c|
  c.include SpecUtils
  c.extend SpecUtils

  c.before(:suite) do
    hosts.each do |host|
      PackageHelpers.install_pdk_on(host)
    end
  end

  c.include_context :set_path

  # rubocop:disable RSpec/BeforeAfterAll
  c.before(:all) do
    RSpec.configuration.logger.log_level = :warn
  end

  c.after(:all) do
    RSpec.configuration.logger.log_level = :verbose
  end
  # rubocop:enable RSpec/BeforeAfterAll

  c.after(:each) do
    cmd = if windows_node?
            command('rm -Recurse -Force $env:LOCALAPPDATA/PDK/Cache/ruby')
          else
            command('rm -rf ~/.pdk/cache/ruby')
          end

    # clear out any cached gems
    cmd.run
  end
end
