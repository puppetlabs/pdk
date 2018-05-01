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
end
