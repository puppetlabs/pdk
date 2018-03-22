# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'pdk bundle' do
  context 'in a new module' do
    include_context 'in a new module', 'bundle'

    describe command('pdk bundle env') do
      its(:exit_status) { is_expected.to eq 0 }
      # use this weird regex to match for empty string to get proper diff output on failure
      its(:stdout) { is_expected.to match(%r{\A\Z}) }
      its(:stderr) { is_expected.to match(%r{## Environment}) }
    end
  end
end
