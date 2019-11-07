require 'spec_helper'
require 'pdk/validate/metadata/metadata_syntax'

describe PDK::Validate::MetadataSyntax do
  let(:module_root) { File.join('path', 'to', 'test', 'module') }

  before(:each) do
    allow(PDK::Util).to receive(:module_root).and_return(module_root)
    allow(PDK::Util::Filesystem).to receive(:directory?).with(module_root).and_return(true)
  end

  it_behaves_like 'it accepts metadata.json targets'

  describe '.invoke' do
    subject(:return_value) { described_class.invoke(report, targets: targets.map { |r| r[:name] }) }

    let(:report) { PDK::Report.new }
    let(:targets) { [] }

    before(:each) do
      targets.each do |target|
        allow(PDK::Util::Filesystem).to receive(:directory?).with(target[:name]).and_return(target.fetch(:directory, false))
        allow(PDK::Util::Filesystem).to receive(:file?).with(target[:name]).and_return(target.fetch(:file, true))
        allow(PDK::Util::Filesystem).to receive(:readable?).with(target[:name]).and_return(target.fetch(:readable, true))
        allow(File).to receive(:read).with(target[:name]).and_return(target.fetch(:content, ''))
      end
    end

    context 'when no valid targets are provided' do
      it 'does not attempt to validate files' do
        expect(report).to receive(:add_event).with(
          file:     module_root,
          source:   'metadata-syntax',
          state:    :skipped,
          severity: :info,
          message:  a_string_matching(%r{\ATarget does not contain any}),
        )
        expect(return_value).to eq(0)
      end
    end

    context 'when a target is provided that is an unreadable file' do
      let(:targets) do
        [
          { name: 'metadata.json', readable: false },
        ]
      end

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first[:name],
          source:   'metadata-syntax',
          state:    :failure,
          severity: 'error',
          message:  'Could not be read.',
        )
        expect(return_value).to eq(1)
      end
    end

    context 'when a target is provided that contains valid JSON' do
      let(:targets) do
        [
          { name: 'metadata.json', content: '{"test": "value"}' },
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
          { name: 'metadata.json', content: '{"test"": "value"}' },
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
          { name: 'invalid/metadata.json', content: '{"test": "value",}' },
          { name: 'metadata.json', content: '{"test": "value"}' },
        ]
      end

      it 'adds events for all valid and skipped targets to the report' do
        expect(report).to receive(:add_event).with(
          file:     'invalid/metadata.json',
          source:   'metadata-syntax',
          state:    :skipped,
          severity: :info,
          message:  a_string_matching(%r{\ATarget does not contain any}),
        )
        expect(report).to receive(:add_event).with(
          file:     'metadata.json',
          source:   'metadata-syntax',
          state:    :passed,
          severity: 'ok',
        )
        expect(return_value).to eq(0)
      end
    end
  end
end
