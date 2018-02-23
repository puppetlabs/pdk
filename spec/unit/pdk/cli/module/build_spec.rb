require 'spec_helper'

describe 'Running pdk module build' do
  subject { PDK::CLI.instance_variable_get(:@module_build_cmd) }

  describe 'when called' do
    it do
      expect(logger).to receive(:warn).with(%r{Modules are built using the ‘pdk build’ command}i)
      expect {
        PDK::CLI.run(%w[module build])
      }.to exit_nonzero
    end
  end
end
