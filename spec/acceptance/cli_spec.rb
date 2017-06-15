require 'spec_helper_acceptance'

describe 'Basic usage of the CLI' do
  describe command('pdk --help') do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match(%r{NAME.*USAGE.*DESCRIPTION.*COMMANDS.*OPTIONS}m) }
    its(:stderr) { is_expected.to match(%r{\A\Z}) }
  end
end
