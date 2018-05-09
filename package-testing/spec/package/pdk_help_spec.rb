require 'spec_helper_package'

describe 'C100022 - pdk --help' do
  describe command('pdk --help') do
    its(:exit_status) { is_expected.to eq(0) }
    its(:stdout) { is_expected.to match(%r{NAME.*USAGE.*DESCRIPTION.*COMMANDS.*OPTIONS}m) }
  end
end
