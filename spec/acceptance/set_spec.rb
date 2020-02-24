require 'spec_helper_acceptance'
require 'fileutils'

describe 'pdk set' do
  include_context 'with a fake TTY'

  context 'when run outside of a module' do
    describe command('pdk set') do
      its(:exit_status) { is_expected.to eq 0 }
      # Should show the command help
      its(:stdout) { is_expected.to match(%r{pdk set \[subcommand\] \[options\]}) }
      its(:stderr) { is_expected.to have_no_output }
    end
  end
end
