require 'spec_helper'
require 'pdk/validate/tasks/tasks_name_validator'

describe PDK::Validate::Tasks::TasksMetadataLintValidator do
  let(:schema) do
    {
      'title' => 'Puppet Task Metadata',
      'description' => 'The metadata format for Puppet Tasks',
      'type' => 'object',
      'properties' => {
        'description' => {
          'type' => 'string',
        },
        'version' => {
          'type' => 'integer',
        },
      },
    }
  end

  describe '.name' do
    subject { described_class.new.name }

    it { is_expected.to eq('task-metadata-lint') }
  end

  describe '.spinner_text' do
    subject(:spinner_text) { described_class.new.spinner_text }

    it { is_expected.to match(/Checking task metadata style/i) }
  end

  describe '.validate_target' do
    subject(:return_value) { validator.validate_target(report, target[:name]) }

    let(:validator) { described_class.new }
    let(:report) { PDK::Report.new }

    before do
      allow(validator).to receive(:schema_file).and_return(schema)
      allow(PDK::Util::Filesystem).to receive(:directory?).with(target[:name]).and_return(target.fetch(:directory, false))
      allow(PDK::Util::Filesystem).to receive(:file?).with(target[:name]).and_return(target.fetch(:file, true))
      allow(PDK::Util::Filesystem).to receive(:readable?).with(target[:name]).and_return(target.fetch(:readable, true))
      allow(PDK::Util::Filesystem).to receive(:read_file).with(target[:name]).and_return(target.fetch(:content, ''))
    end

    context 'when a target is provided that is an unreadable file' do
      let(:target) do
        { name: 'tasks/unreadable.json', readable: false }
      end

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: 'task-metadata-lint',
                                                     state: :failure,
                                                     severity: 'error',
                                                     message: 'Could not be read.',
                                                   })
        expect(return_value).to eq(1)
      end
    end

    context 'when a target is provided that contains valid JSON' do
      let(:target) do
        {
          name: 'tasks/valid.json',
          content: '{"description": "wow. so. valid.", "version": 1}',
        }
      end

      it 'adds a passing event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: 'task-metadata-lint',
                                                     state: :passed,
                                                     severity: 'ok',
                                                   })
        expect(return_value).to eq(0)
      end
    end

    context 'when a target is provided that contains invalid JSON' do
      let(:target) do
        {
          name: 'tasks/invalid.json',
          content: '{"description": "Invalid Metadata", "version": "definitely the wrong type"}',
        }
      end

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: 'task-metadata-lint',
                                                     state: :failure,
                                                     severity: 'error',
                                                     message: a_string_matching(/did not match the following type/i),
                                                   })
        expect(return_value).to eq(1)
      end
    end
  end
end
