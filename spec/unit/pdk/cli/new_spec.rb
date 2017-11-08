require 'spec_helper'

describe 'Running `pdk new`' do
  subject { PDK::CLI.instance_variable_get(:@new_cmd) }

  context 'when no arguments or options are provided' do
    it do
      expect {
        PDK::CLI.run(['new'])
      }.to output(%r{^USAGE\s+pdk new}m).to_stdout
    end
  end
end
