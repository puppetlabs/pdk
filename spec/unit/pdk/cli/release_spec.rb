require 'spec_helper'

describe 'PDK::CLI release' do
  let(:help_text) { a_string_matching(%r{^USAGE\s+pdk release}m) }

  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(%r{must be run from inside a valid module}))
      expect { PDK::CLI.run(%w[release]) }.to exit_nonzero
    end
  end
end
