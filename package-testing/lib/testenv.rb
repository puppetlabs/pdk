require 'spec_helper_package'

RSpec.configure do |c|
  c.after(:suite) do
    puts "\nTarget host successfully provisioned with PDK:"
    puts "\n#{hosts.first.hostname}\n"
  end
end

describe 'validate PDK was successfully installed' do
  describe command('pdk --version') do
    its(:exit_status) { is_expected.to eq(0) }
  end
end
