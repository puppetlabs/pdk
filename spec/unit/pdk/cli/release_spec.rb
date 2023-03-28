require 'spec_helper'
require 'pdk/cli'

describe 'PDK::CLI release' do
  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(/must be run from inside a valid module/))
      expect { PDK::CLI.run(['release']) }.to exit_nonzero
    end
  end

  context 'when run inside a module' do
    let(:release_object) do
      instance_double(
        PDK::Module::Release,
        pdk_compatible?: true,
        module_metadata: mock_metadata_obj,
        run: nil,
      )
    end

    let(:mock_metadata_obj) do
      instance_double(
        PDK::Module::Metadata,
        forge_ready?: true,
      )
    end

    before do
      allow(PDK::CLI::Util).to receive(:ensure_in_module!).and_return(nil)
      allow(PDK::Module::Release).to receive(:new).and_return(release_object)
      allow(PDK::Util).to receive(:exit_process).and_raise('exit_process mock should not be called')
    end

    it 'calls PDK::Module::Release.new with the correct opts' do
      expect(PDK::Module::Release).to receive(:new).with(Object, hash_including(
                                                                   'forge-token': 'cli123',
                                                                   force: true,
                                                                   'forge-upload-url': 'https://example.com',
                                                                 ))
      PDK::CLI.run(['release', '--forge-token=cli123', '--force', '--forge-upload-url=https://example.com'])
    end

    it 'calls PDK::Module::Release.run' do
      expect(release_object).to receive(:run).and_return(nil)

      expect { PDK::CLI.run(['release', '--force']) }.not_to raise_error
    end

    it 'does not start an interview when --force is used' do
      expect(PDK::CLI::Util::Interview).not_to receive(:new)

      PDK::CLI.run(['release', '--force'])
    end

    it 'calls PDK::CLI::Release.module_compatibility_checks!' do
      expect(PDK::CLI::Release).to receive(:module_compatibility_checks!).and_return(nil)

      expect { PDK::CLI.run(['release', '--force']) }.not_to raise_error
    end
  end

  describe '#module_compatibility_checks!' do
    let(:release_object) do
      instance_double(
        PDK::Module::Release,
        pdk_compatible?: true,
        module_metadata: mock_metadata_obj,
        run: nil,
      )
    end

    let(:mock_metadata_obj) do
      instance_double(
        PDK::Module::Metadata,
        forge_ready?: true,
      )
    end

    let(:opts) { { force: true } }
    let(:release) { PDK::CLI::Release }

    context 'With a module that is not forge ready' do
      before do
        allow(mock_metadata_obj).to receive(:forge_ready?).and_return(false)
        allow(mock_metadata_obj).to receive(:missing_fields).and_return(['mock_field'])
      end

      it 'raises a warning' do
        expect(PDK.logger).to receive(:warn).with(/mock_field/)
        release.module_compatibility_checks!(release_object, opts)
      end
    end

    context 'With a module that is not pdk compatibler' do
      before do
        allow(release_object).to receive(:pdk_compatible?).and_return(false)
      end

      it 'raises a warning' do
        expect(PDK.logger).to receive(:warn).with(/not compatible with PDK/)
        release.module_compatibility_checks!(release_object, opts)
      end
    end
  end
end
