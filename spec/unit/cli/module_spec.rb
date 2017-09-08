require 'spec_helper'

describe 'Running `pdk module`' do
  subject { PDK::CLI.instance_variable_get(:@module_cmd) }

  context 'when no arguments or options are provided' do
    it do
      expect {
        PDK::CLI.run(['module'])
      }.to output(%r{^USAGE\s+pdk module}m).to_stdout
    end
  end
end
