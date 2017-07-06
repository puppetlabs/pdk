require 'spec_helper'

describe PDK::Validate::MetadataSyntax do
  let(:module_root) { File.join('path', 'to', 'test', 'module') }

  before(:each) do
    allow(PDK::Util).to receive(:module_root).and_return(module_root)
    allow(File).to receive(:directory?).with(module_root).and_return(true)
  end

  describe '.parse_targets' do
    subject { described_class.parse_targets(targets: targets) }

    context 'when given no targets' do
      let(:module_metadata_json) { File.join(module_root, 'metadata.json') }
      let(:glob_pattern) { File.join(module_root, described_class.pattern) }
      let(:targets) { [] }

      context 'and the module contains a metadata.json file' do
        before(:each) do
          allow(Dir).to receive(:glob).with(glob_pattern).and_return(module_metadata_json)
        end

        it 'returns the path to metadata.json in the module' do
          is_expected.to eq([module_metadata_json])
        end
      end

      context 'and the module does not contain a metadata.json file' do
        before(:each) do
          allow(Dir).to receive(:glob).with(glob_pattern).and_return([])
        end

        it 'returns no targets' do
          is_expected.to eq([])
        end
      end
    end

    context 'when given specific target files' do
      let(:targets) { ['target1', 'target2.json'] }

      before(:each) do
        targets.each do |target|
          allow(File).to receive(:directory?).with(target).and_return(false)
        end
      end

      it 'returns the targets' do
        is_expected.to eq(targets)
      end
    end

    context 'when given a specific target directory' do
      let(:targets) { [File.join('path', 'to', 'target', 'directory')] }
      let(:glob_pattern) { File.join(targets.first, described_class.pattern) }

      before(:each) do
        allow(File).to receive(:directory?).with(targets.first).and_return(true)
      end

      context 'and the directory contains a metadata.json file' do
        let(:expected_targets) { [File.join(targets.first, 'metadata.json')] }

        before(:each) do
          allow(Dir).to receive(:glob).with(glob_pattern).and_return(expected_targets)
        end

        it 'returns the path to the metadata.json file in the target directory' do
          is_expected.to eq(expected_targets)
        end
      end

      context 'and the directory does not contain a metadata.json file' do
        before(:each) do
          allow(Dir).to receive(:glob).with(glob_pattern).and_return([])
        end

        it 'returns no targets' do
          is_expected.to eq([])
        end
      end
    end
  end

  describe '.invoke' do
    subject(:return_value) { described_class.invoke(report, targets: targets.map { |r| r[:name] }) }

    let(:report) { PDK::Report.new }
    let(:targets) { [] }

    before(:each) do
      targets.each do |target|
        allow(File).to receive(:directory?).with(target[:name]).and_return(target.fetch(:directory, false))
        allow(File).to receive(:file?).with(target[:name]).and_return(target.fetch(:file, true))
        allow(File).to receive(:readable?).with(target[:name]).and_return(target.fetch(:readable, true))
        allow(File).to receive(:read).with(target[:name]).and_return(target.fetch(:content, ''))
      end
    end

    context 'when no valid targets are provided' do
      it 'does not attempt to validate files' do
        expect(report).not_to receive(:add_event)
        expect(return_value).to eq(0)
      end
    end

    context 'when a target is provided that is not a file' do
      let(:targets) do
        [
          { name: 'not_file', file: false },
        ]
      end

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first[:name],
          source:   'metadata-syntax',
          state:    :failure,
          severity: 'error',
          message:  'not a file',
        )
        expect(return_value).to eq(1)
      end
    end

    context 'when a target is provided that is an unreadable file' do
      let(:targets) do
        [
          { name: 'not_readable', readable: false },
        ]
      end

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first[:name],
          source:   'metadata-syntax',
          state:    :failure,
          severity: 'error',
          message:  'could not be read',
        )
        expect(return_value).to eq(1)
      end
    end

    context 'when a target is provided that contains valid JSON' do
      let(:targets) do
        [
          { name: 'valid_file', content: '{"test": "value"}' },
        ]
      end

      it 'adds a passing event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first[:name],
          source:   'metadata-syntax',
          state:    :passed,
          severity: 'ok',
        )
        expect(return_value).to eq(0)
      end
    end

    context 'when a target is provided that contains invalid JSON' do
      let(:targets) do
        [
          { name: 'invalid_file', content: '{"test"": "value"}' },
        ]
      end

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first[:name],
          source:   'metadata-syntax',
          state:    :failure,
          severity: 'error',
          message:  a_string_matching(%r{\Aexpected ':' in object}),
        )
        expect(return_value).to eq(1)
      end
    end

    context 'when targets are provided that contain valid and invalid JSON' do
      let(:targets) do
        [
          { name: 'invalid_file', content: '{"test": "value",}' },
          { name: 'valid_file', content: '{"test": "value"}' },
        ]
      end

      it 'adds events for all targets to the report' do
        expect(report).to receive(:add_event).with(
          file:     'invalid_file',
          source:   'metadata-syntax',
          state:    :failure,
          severity: 'error',
          message:  a_string_matching(%r{\Aexpected next name}),
        )
        expect(report).to receive(:add_event).with(
          file:     'valid_file',
          source:   'metadata-syntax',
          state:    :passed,
          severity: 'ok',
        )
        expect(return_value).to eq(1)
      end
    end
  end
end
