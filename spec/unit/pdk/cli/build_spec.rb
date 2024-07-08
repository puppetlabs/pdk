require 'spec_helper'
require 'pdk/cli'
require 'puppet/modulebuilder'

describe 'PDK::CLI build' do
  let(:help_text) { a_string_matching(/^USAGE\s+pdk build/m) }
  let(:command_opts) { [] }

  shared_context 'exits cleanly' do
    after do
      PDK::CLI.run(['build'] + command_opts)
    end
  end

  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(/must be run from inside a valid module/))

      expect { PDK::CLI.run(['build']) }.to exit_nonzero
    end
  end

  context 'when run from inside a module' do
    before do
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/test/module')
      allow(PDK::Module::Metadata).to receive(:from_file).with(/metadata.json/).and_return(mock_metadata_obj)
      allow(Puppet::Modulebuilder::Builder).to receive(:new).and_return(mock_builder)
    end

    let(:command_opts) { [] }
    let(:mock_metadata) do
      {
        'name' => 'testuser-testmodule',
        'version' => '2.3.4'
      }
    end
    let(:mock_metadata_obj) do
      instance_double(
        PDK::Module::Metadata,
        data: mock_metadata,
        forge_ready?: true,
        interview_for_forge!: true
      )
    end
    let(:package_path) { File.join(Dir.pwd, 'pkg', 'testuser-testmodule-2.3.4.tar.gz') }
    let(:mock_builder) do
      instance_double(
        Puppet::Modulebuilder::Builder,
        build: true,
        package_already_exists?: false,
        package_file: package_path
      )
    end

    context 'and the module contains incomplete metadata' do
      before do
        allow(PDK::Util).to receive(:module_pdk_compatible?).and_return(true)
        allow(mock_metadata_obj).to receive_messages(forge_ready?: false, missing_fields: ['operatingsystem_support', 'source'])
        allow(Puppet::Modulebuilder::Builder).to receive(:new).with(any_args).and_return(mock_builder)
      end

      context 'with default options' do
        include_context 'exits cleanly'

        it 'interviews the user for the missing data and updates the metadata.json file' do
          expect(mock_metadata_obj).to receive(:interview_for_forge!)
          expect(mock_metadata_obj).to receive(:write!).with('metadata.json')
        end
      end

      context 'with --force option' do
        let(:command_opts) { ['--force'] }

        it 'outputs an warning and continues' do
          expect(logger).to receive(:warn).with(a_string_matching(/fields in the metadata\.json: operatingsystem_support, source/im))

          expect { PDK::CLI.run(['build'] + command_opts) }.not_to raise_error
        end
      end
    end

    context 'and the module contains complete metadata' do
      include_context 'exits cleanly'

      before do
        allow(PDK::Util).to receive_messages(module_pdk_compatible?: true, forge_ready?: true)
        allow(Puppet::Modulebuilder::Builder).to receive(:new).with(any_args).and_return(mock_builder)
      end

      it 'does not interview the user' do
        expect(mock_metadata_obj).not_to receive(:interview_for_forge!)
        expect(mock_metadata_obj).not_to receive(:write!)
      end
    end

    context 'and provided no flags' do
      include_context 'exits cleanly'

      it 'invokes the builder with the default target directory' do
        allow(PDK::Util).to receive(:module_pdk_compatible?).and_return(true)
        expect(Puppet::Modulebuilder::Builder).to receive(:new).with(Dir.pwd, File.join(Dir.pwd, 'pkg'), anything).and_return(mock_builder)
      end
    end

    context 'and provided with the --target-dir option' do
      include_context 'exits cleanly'

      let(:command_opts) { ['--target-dir', '/tmp/pdk_builds'] }

      it 'invokes the builder with the specified target directory' do
        allow(PDK::Util).to receive(:module_pdk_compatible?).and_return(true)
        expect(Puppet::Modulebuilder::Builder).to receive(:new).with(Dir.pwd, '/tmp/pdk_builds', anything).and_return(mock_builder)
      end
    end

    context 'package already exists in the target dir' do
      before do
        allow(mock_builder).to receive_messages(package_already_exists?: true)
        allow(PDK::Util).to receive(:module_pdk_compatible?).and_return(true)
      end

      context 'user chooses to continue' do
        include_context 'exits cleanly'

        before do
          allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(true)
          allow(mock_builder).to receive(:package_file).and_return('testuser-testmodule')
        end

        it 'continue to build' do
          expect(logger).to receive(:info).with(a_string_matching(/The file 'testuser-testmodule' already exists/i))
          expect(PDK::CLI::Util).to receive(:prompt_for_yes).with(a_string_matching(/Overwrite/i), default: false).and_return(true)
        end
      end

      context 'user chooses to cancel' do
        before do
          allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(false)
          allow(mock_builder).to receive(:package_file).and_return('testuser-testmodule')
        end

        it 'cancel' do
          expect(logger).to receive(:info).with(a_string_matching(/The file 'testuser-testmodule' already exists/i))
          expect(PDK::CLI::Util).to receive(:prompt_for_yes).with(a_string_matching(/Overwrite/i), default: false).and_return(false)

          expect { PDK::CLI.run(['build'] + command_opts) }.to exit_zero
        end
      end
    end

    context 'and module is not pdk compatible' do
      before do
        allow(mock_builder).to receive_messages(package_already_exists?: false)
        allow(PDK::Util).to receive(:module_pdk_compatible?).and_return(false)
      end

      context 'user chooses to continue' do
        include_context 'exits cleanly'

        before do
          allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(true)
          allow(mock_builder).to receive(:package_file).and_return('testuser-testmodule')
        end

        it 'continue to build' do
          expect(logger).to receive(:info).with(a_string_matching(/This module is not compatible with PDK/))
          expect(PDK::CLI::Util).to receive(:prompt_for_yes).with(a_string_matching(/Continue build without converting/i)).and_return(true)
        end
      end

      context 'user chooses to cancel' do
        before do
          allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(false)
          allow(mock_builder).to receive(:package_file).and_return('testuser-testmodule')
        end

        it 'cancel' do
          expect(logger).to receive(:info).with(a_string_matching(/This module is not compatible with PDK/))
          expect(PDK::CLI::Util).to receive(:prompt_for_yes).with(a_string_matching(/Continue build without converting/i)).and_return(false)
          expect { PDK::CLI.run(['build'] + command_opts) }.to exit_zero
        end
      end
    end
  end
end
