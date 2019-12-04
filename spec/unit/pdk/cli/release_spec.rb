require 'spec_helper'
require 'pdk/cli'

describe 'PDK::CLI release' do
  let(:help_text) { a_string_matching(%r{^USAGE\s+pdk release}m) }

  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(%r{must be run from inside a valid module}))
      expect { PDK::CLI.run(%w[release]) }.to exit_nonzero
    end
  end

  context 'when run inside a module' do
    let(:release_object) do
      instance_double(
        PDK::Module::Release,
        pdk_compatible?: true,
        module_metadata: mock_metadata_obj,
      )
    end

    let(:mock_metadata_obj) do
      instance_double(
        PDK::Module::Metadata,
        forge_ready?: true,
      )
    end

    before(:each) do
      allow(PDK::CLI::Util).to receive(:ensure_in_module!).and_return(nil)
      allow(PDK::Module::Release).to receive(:new).and_return(release_object)
      allow(PDK::Util).to receive(:exit_process).and_raise('exit_process mock should not be called')
      expect(release_object).to receive(:run).and_return(nil)
    end

    it 'calls PDK::Module::Release.run' do
      expect { PDK::CLI.run(%w[release --force]) }.not_to raise_error
    end
  end
end
