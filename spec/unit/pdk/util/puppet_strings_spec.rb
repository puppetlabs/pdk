require 'spec_helper'

describe PDK::Util::PuppetStrings do
  describe '.puppet' do
    before(:each) do
      allow(PDK::Util::Bundler).to receive(:ensure_binstubs!).with('puppet')
      allow(PDK::Util).to receive(:module_root).and_return(module_root)
      allow(PDK::Util::RubyVersion).to receive(:bin_path).and_return(ruby_path)
    end

    let(:module_root) { File.join('path', 'to', 'module') }
    let(:ruby_path) { File.join('path', 'to', 'ruby') }
    let(:mock_command) do
      instance_double(PDK::CLI::Exec::Command,
                      :'context=' => true,
                      :add_spinner => true)
    end
    let(:command_args) { %w[some args] }

    context 'on Windows' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(true)

        allow(PDK::CLI::Exec::Command).to receive(:new).with(
          File.join(ruby_path, 'ruby.exe'),
          File.join(module_root, 'bin', 'puppet'),
          *command_args,
        ).and_return(mock_command)
      end

      it 'prepends the path to the ruby binary to the command' do
        expect(mock_command).to receive(:execute!)

        described_class.puppet(*command_args)
      end

      it 'returns the result of the command execution' do
        allow(mock_command).to receive(:execute!).and_return('command result')

        expect(described_class.puppet(*command_args)).to eq('command result')
      end
    end

    context 'on nix' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(false)

        allow(PDK::CLI::Exec::Command).to receive(:new).with(
          File.join(module_root, 'bin', 'puppet'),
          *command_args,
        ).and_return(mock_command)
      end

      it 'does not prepend the path to the ruby binary' do
        expect(mock_command).to receive(:execute!)

        described_class.puppet(*command_args)
      end

      it 'returns the result of the command execution' do
        allow(mock_command).to receive(:execute!).and_return('command result')

        expect(described_class.puppet(*command_args)).to eq('command result')
      end
    end
  end

  describe '.generate_hash' do
    before(:each) do
      allow(described_class).to receive(:puppet)
        .with('strings', 'generate', '--format', 'json').and_return(result)
    end

    context 'when the command fails' do
      let(:result) do
        {
          exit_code: 1,
          stderr:    'some error text',
        }
      end

      it 'raises a PDK::Util::PuppetStrings::RunError' do
        expect {
          described_class.generate_hash
        }.to raise_error(described_class::RunError, 'some error text')
      end
    end

    context 'when the command outputs invalid JSON' do
      let(:result) do
        {
          exit_code: 0,
          stdout:    'bleh]',
        }
      end

      it 'raises a PDK::Util::PuppetStrings::RunError' do
        expect {
          described_class.generate_hash
        }.to raise_error(described_class::RunError, 'Unable to parse puppet-strings output')
      end
    end

    context 'when the command outputs valid JSON' do
      let(:result) do
        {
          exit_code: 0,
          stdout:    '{ "puppet_classes": [] }',
        }
      end

      it 'returns the parsed JSON object' do
        expect(described_class.generate_hash).to eq('puppet_classes' => [])
      end
    end
  end

  describe '.find_object' do
    before(:each) do
      allow(described_class).to receive(:generate_hash)
        .and_return(puppet_strings_data)
      allow(PDK::Util).to receive(:module_metadata).and_return(metadata_hash)
    end

    let(:metadata_hash) do
      {
        'name' => 'myuser-mymodule',
      }
    end

    context 'when the object is not found in puppet-strings' do
      let(:puppet_strings_data) do
        {
          'puppet_classes' => [],
          'defined_types' => [],
        }
      end

      it 'raises PDK::Util::PuppetStrings::NoObjectError' do
        expect {
          described_class.find_object('my_object')
        }.to raise_error(described_class::NoObjectError)
      end
    end

    context 'when the object is found in puppet-strings' do
      context 'and there is a generator for the object' do
        let(:puppet_strings_data) do
          {
            'puppet_classes' => [],
            'defined_types' => [
              { 'name' => 'mymodule::my_object' },
            ],
          }
        end

        it 'returns the generator class and the description hash' do
          expect(described_class.find_object('my_object'))
            .to eq([PDK::Generate::DefinedType, { 'name' => 'mymodule::my_object' }])
        end
      end

      context 'but there is no generator for the object' do
        let(:puppet_strings_data) do
          {
            'puppet_classes' => [],
            'defined_types' => [],
            'data_types' => [
              { 'name' => 'mymodule::my_object' },
            ],
          }
        end

        it 'raises PDK::Util::PuppetStrings::NoGeneratorError' do
          expect {
            described_class.find_object('my_object')
          }.to raise_error(described_class::NoGeneratorError, 'data_types')
        end
      end
    end
  end

  describe '.find_generator' do
    subject { described_class.find_generator(type) }

    context 'when passed "puppet_classes"' do
      let(:type) { 'puppet_classes' }

      it { is_expected.to eq(PDK::Generate::PuppetClass) }
    end

    context 'when passed "defined_types"' do
      let(:type) { 'defined_types' }

      it { is_expected.to eq(PDK::Generate::DefinedType) }
    end

    context 'when passed any other value' do
      let(:type) { 'data_type' }

      it { is_expected.to be_nil }
    end
  end
end
