require 'spec_helper'
require 'pdk/validate/metadata/metadata_syntax_validator'

describe PDK::Validate::Metadata::MetadataSyntaxValidator do
  subject(:validator) { described_class.new(validator_context, targets: targets.map { |r| r[:name] }) }

  let(:validator_context) { nil }
  let(:targets) { [] }

  describe '.pattern' do
    it 'only matches metadata JSON files' do
      expect(validator.pattern).to eq(['metadata.json', 'tasks/*.json'])
    end
  end

  describe '.invoke' do
    subject(:return_value) { validator.invoke(report) }

    let(:report) { PDK::Report.new }

    before(:each) do
      targets.each do |target|
        allow(PDK::Util::Filesystem).to receive(:directory?).with(target[:name]).and_return(target.fetch(:directory, false))
        allow(PDK::Util::Filesystem).to receive(:file?).with(target[:name]).and_return(target.fetch(:file, true))
        allow(PDK::Util::Filesystem).to receive(:readable?).with(target[:name]).and_return(target.fetch(:readable, true))
        allow(PDK::Util::Filesystem).to receive(:read_file).with(target[:name]).and_return(target.fetch(:content, ''))
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
  end
end
