require 'spec_helper'

describe 'Running `pdk test`' do
  subject { PDK::CLI.instance_variable_get(:@test_cmd) }

  it { is_expected.not_to be_nil }

  context 'when no arguments or options are provided' do
    it do
      expect {
        PDK::CLI.run(['test'])
      }.to output(%r{^USAGE\s+pdk test}m).to_stdout
    end
  end
end
