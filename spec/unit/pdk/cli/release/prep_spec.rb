require 'spec_helper'
require 'pdk/cli'

describe 'PDK::CLI release prep' do
  let(:help_text) { a_string_matching(/^USAGE\s+pdk release prep/m) }
  let(:cli_args) { ['release', 'prep'] }

  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(/must be run from inside a valid module/))

      expect { PDK::CLI.run(cli_args) }.to exit_nonzero
    end

    it 'does not submit the command to analytics' do
      expect(analytics).not_to receive(:screen_view)

      expect { PDK::CLI.run(cli_args) }.to exit_nonzero
    end
  end

  context 'when run from inside a module' do
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

    it 'calls PDK::Module::Release.run' do
      expect(release_object).to receive(:run)

      expect { PDK::CLI.run(cli_args.push('--force')) }.not_to raise_error
    end

    it 'skips building and publishing' do
      expect(PDK::Module::Release).to receive(:new).with(Object, hash_including('skip-build': true, 'skip-publish': true))

      expect { PDK::CLI.run(cli_args.push('--force')) }.not_to raise_error
    end

    it 'does not start an interview when --force is used' do
      expect(PDK::CLI::Util::Interview).not_to receive(:new)

      PDK::CLI.run(cli_args.push('--force'))
    end

    it 'calls PDK::CLI::Release.module_compatibility_checks!' do
      expect(PDK::CLI::Release).to receive(:module_compatibility_checks!).and_return(nil)

      expect { PDK::CLI.run(cli_args.push('--force')) }.not_to raise_error
    end
  end
end
