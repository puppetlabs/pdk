require 'spec_helper'

describe 'PDK::CLI build' do
  let(:help_text) { a_string_matching(%r{^USAGE\s+pdk build}m) }

  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(%r{must be run from inside a valid module}))

      expect {
        PDK::CLI.run(%w[build])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).not_to eq(0)
      }
    end
  end

  context 'when run from inside a module' do
    before(:each) do
      mock_metadata_obj = instance_double(PDK::Module::Metadata, data: mock_metadata)

      allow(PDK::Util).to receive(:module_root).and_return('/path/to/test/module')
      allow(PDK::Module::Metadata).to receive(:from_file).with('metadata.json').and_return(mock_metadata_obj)
      allow(PDK::Module::Build).to receive(:invoke).with(:'target-dir' => File.join(Dir.pwd, 'pkg')).and_return(package_path)
    end

    after(:each) do
      PDK::CLI.run(['build'] + command_opts)
    end

    let(:command_opts) { [] }
    let(:mock_metadata) do
      {
        'name'    => 'testuser-testmodule',
        'version' => '2.3.4',
      }
    end
    let(:package_path) { File.join(Dir.pwd, 'pkg', 'testuser-testmodule-2.3.4.tar.gz') }

    it 'informs the user of the module that is being built' do
      expect(logger).to receive(:info).with(a_string_matching(%r{#{mock_metadata['name']} version #{mock_metadata['version']}}i))
    end

    it 'informs the user of the path to the package on successful build' do
      expect(logger).to receive(:info).with(a_string_matching(%r{package can be found.+#{Regexp.escape(package_path)}}i))
    end

    context 'and provided no flags' do
      it 'invokes the builder with the default target directory' do
        expect(PDK::Module::Build).to receive(:invoke).with(:'target-dir' => File.join(Dir.pwd, 'pkg'))
      end
    end

    context 'and provided with the --target-dir option' do
      let(:command_opts) { ['--target-dir', '/tmp/pdk_builds'] }

      it 'invokes the builder with the specified target directory' do
        expect(PDK::Module::Build).to receive(:invoke).with(:'target-dir' => '/tmp/pdk_builds')
      end
    end
  end
end
