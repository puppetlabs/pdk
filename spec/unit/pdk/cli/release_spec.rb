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
    # make rubocop happy
    # rubocop:disable RSpec/AnyInstance
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return(nil)
      allow(PDK::Module::Metadata).to receive(:from_file).with('metadata.json').and_return(mock_metadata_obj)
      allow(PDK::CLI::Util).to receive(:ensure_in_module!).and_return(true)
      allow_any_instance_of(Cri::CommandDSL).to receive(:run_validations).and_return(nil)
      allow_any_instance_of(Cri::CommandDSL).to receive(:build_module).with(anything, anything).and_return(nil)
      allow_any_instance_of(Cri::CommandDSL).to receive(:push_to_forge).with(anything, anything).and_return(0)
    end
    # rubocop:enable RSpec/AnyInstance

    let(:mock_metadata) do
      {
        'name'    => 'testuser-testmodule',
        'version' => '2.3.4',
      }
    end
    let(:command_response) do
      {
        'exit_code' => 0,
      }
    end
    let(:mock_metadata_obj) do
      instance_double(
        PDK::Module::Metadata,
        data:                 mock_metadata,
        forge_ready?:         true,
        interview_for_forge!: true,
      )
    end
    let(:mock_changelog) { instance_double(PDK::CLI::Util::ChangelogGenerator) }
    let(:mock_command) { instance_double(PDK::CLI::Exec::Command) }
    let(:package_path) { File.join(Dir.pwd, 'pkg', 'testuser-testmodule-2.3.4.tar.gz') }

    it 'follows release process with skipping changelog, documentation and dependency updates' do
      allow(PDK::Module::Metadata).to receive(:write!).with('metadata.json').and_return(nil)
      expect(logger).to receive(:info).with(a_string_matching(%r{Releasing testuser-testmodule}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping automatic changelog}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping documentation update}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping dependency}))
      expect { PDK::CLI.run(%w[release --force --skip_changelog --skip_dependency --skip_documentation]) }.not_to raise_error
    end

    it 'follows release process with changelog generation, skipping documentation and dependency updates' do
      allow(PDK::CLI::Util::ChangelogGenerator).to receive(:new).and_return(mock_changelog)
      allow(mock_changelog).to receive(:generate_changelog).and_return(nil)
      allow(mock_changelog).to receive(:get_next_version).with(mock_metadata['version']).and_return('2.4.0')
      allow(mock_metadata_obj).to receive(:write!).with('metadata.json').and_return(nil)
      expect(logger).to receive(:info).with(a_string_matching(%r{Releasing testuser-testmodule}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Updating version to 2.4.0}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Generating changelog}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping documentation update}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping dependency}))
      expect { PDK::CLI.run(%w[release --force --skip_dependency --skip_documentation]) }.not_to raise_error
    end

    it 'follows release process preparation' do
      allow(PDK::CLI::Util::ChangelogGenerator).to receive(:new).and_return(mock_changelog)
      allow(mock_changelog).to receive(:generate_changelog).and_return(nil)
      allow(mock_changelog).to receive(:get_next_version).with(mock_metadata['version']).and_return('2.4.0')
      allow(mock_metadata_obj).to receive(:write!).with('metadata.json').and_return(nil)

      allow(PDK::CLI::Exec::InteractiveCommand).to receive(:new).and_return(mock_command)
      allow(PDK::CLI::Exec::Command).to receive(:new).with(anything, anything).and_return(mock_command)

      allow(mock_command).to receive(:execute!).and_return(command_response)
      allow(mock_command).to receive(:context=)
      expect(logger).to receive(:info).with(a_string_matching(%r{Releasing testuser-testmodule}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Updating version to 2.4.0}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Generating changelog}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping module build}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping module push}))
      expect { PDK::CLI.run(%w[release prep --force]) }.not_to raise_error
    end

    it 'follows release process build' do
      allow(PDK::CLI::Util::ChangelogGenerator).to receive(:new).and_return(mock_changelog)
      allow(mock_changelog).to receive(:generate_changelog).and_return(nil)
      allow(mock_changelog).to receive(:get_next_version).with(mock_metadata['version']).and_return('2.4.0')
      allow(mock_metadata_obj).to receive(:write!).with('metadata.json').and_return(nil)

      expect(logger).to receive(:info).with(a_string_matching(%r{Releasing testuser-testmodule}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping automatic changelog generation}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping documentation update for this module}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping dependency-cheking on the metadata of this module}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping module push}))
      expect { PDK::CLI.run(%w[release build --force]) }.not_to raise_error
    end

    it 'follows release process push' do
      allow(PDK::CLI::Util::ChangelogGenerator).to receive(:new).and_return(mock_changelog)
      allow(mock_changelog).to receive(:generate_changelog).and_return(nil)
      allow(mock_changelog).to receive(:get_next_version).with(mock_metadata['version']).and_return('2.4.0')
      allow(mock_metadata_obj).to receive(:write!).with('metadata.json').and_return(nil)

      expect(logger).to receive(:info).with(a_string_matching(%r{Releasing testuser-testmodule}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping automatic changelog generation}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping documentation update for this module}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping dependency-cheking on the metadata of this module}))
      expect(logger).to receive(:info).with(a_string_matching(%r{Skipping module build}))
      expect { PDK::CLI.run(%w[release push --force]) }.not_to raise_error
    end
  end
end
