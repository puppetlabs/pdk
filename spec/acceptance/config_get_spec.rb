require 'spec_helper_acceptance'
require 'fileutils'

describe 'pdk config get' do
  include_context 'with a fake TTY'

  context 'when run outside of a module' do
    describe command('pdk config get') do
      its(:exit_status) { is_expected.to eq 0 }
      # This setting should appear in all pdk versions
      its(:stdout) { is_expected.to match(%r{user\.analytics\.user-id=}) }
      its(:stderr) { is_expected.to match(%r{The 'pdk config get' command is deprecated}) }
    end

    describe command('pdk config get user.analytics.disabled') do
      its(:exit_status) { is_expected.to eq 0 }
      # This setting, and only, this setting should appear in output
      its(:stdout) { is_expected.to eq("true\n") }
      its(:stderr) { is_expected.to match(%r{The 'pdk config get' command is deprecated}) }
    end

    describe command('pdk config get user.analytics') do
      its(:exit_status) { is_expected.to eq 0 }
      # There should be two configuration items returned
      its(:stdout) { expect(is_expected.target.split("\n").count).to eq(2) }

      its(:stdout) do
        result = is_expected.target.split("\n").sort
        expect(result[0]).to match('user.analytics.disabled=true')
        expect(result[1]).to match(%r{user.analytics.user-id=.+})
      end

      its(:stderr) { is_expected.to match(%r{The 'pdk config get' command is deprecated}) }
    end

    describe command('pdk config get does.not.exist') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stdout) { is_expected.to have_no_output }
      its(:stderr) { is_expected.to match(%r{does\.not\.exist}) }
    end
  end
end
