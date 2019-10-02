require 'spec_helper'

describe PDK::Validate::Tasks::MetadataLint do
  let(:module_root) { File.join('path', 'to', 'test', 'module') }
  let(:schema) do
    {
      'title'       => 'Puppet Task Metadata',
      'description' => 'The metadata format for Puppet Tasks',
      'type'        => 'object',
      'properties'  => {
        'description' => {
          'type' => 'string',
        },
        'version' => {
          'type' => 'integer',
        },
      },
    }
  end

  before(:each) do
    allow(PDK::Util).to receive(:module_root).and_return(module_root)
    allow(File).to receive(:directory?).with(module_root).and_return(true)
  end

  it 'defines the base validator attributes' do
    expect(described_class).to have_attributes(
      name: 'task-metadata-lint',
    )
  end

  describe '.spinner_text' do
    subject(:spinner_text) { described_class.spinner_text(targets) }

    context 'when given a relative path to the target' do
      let(:targets) { ['tasks/foo.json'] }

      it 'includes the path to the target in the spinner text' do
        expect(spinner_text).to match(%r{checking task metadata style}i)
      end
    end

    context 'when given an absolute path to the target' do
      let(:targets) do
        if Gem.win_platform?
          ['C:/path/to/module/tasks/foo.json']
        else
          ['/path/to/module/tasks/foo.json']
        end
      end

      before(:each) do
        pwd = Gem.win_platform? ? 'C:/path/to/module' : '/path/to/module'
        allow(Pathname).to receive(:pwd).and_return(Pathname.new(pwd))
      end

      it 'includes the path to the target relative to the PWD in the spinner text' do
        expect(spinner_text).to match(%r{checking task metadata style}i)
      end
    end
  end

  describe '.invoke' do
    subject(:return_value) { described_class.invoke(report, targets: targets.map { |r| r[:name] }) }

    let(:report) { PDK::Report.new }
    let(:targets) { [] }

    before(:each) do
      allow(described_class).to receive(:schema_file).and_return(schema)
      allow(File).to receive(:file?).and_call_original
      allow(File).to receive(:read).and_call_original
      targets.each do |target|
        allow(File).to receive(:directory?).with(target[:name]).and_return(target.fetch(:directory, false))
        allow(File).to receive(:file?).with(target[:name]).and_return(target.fetch(:file, true))
        allow(File).to receive(:readable?).with(target[:name]).and_return(target.fetch(:readable, true))
        allow(File).to receive(:read).with(target[:name]).and_return(target.fetch(:content, ''))
      end
    end

    context 'when a target is provided that is an unreadable file' do
      let(:targets) do
        [
          { name: 'tasks/unreadable.json', readable: false },
        ]
      end

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first[:name],
          source:   'task-metadata-lint',
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
          {
            name:    'tasks/valid.json',
            content: '{"description": "wow. so. valid.", "version": 1}',
          },
        ]
      end

      it 'adds a passing event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first[:name],
          source:   'task-metadata-lint',
          state:    :passed,
          severity: 'ok',
        )
        expect(return_value).to eq(0)
      end
    end

    context 'when a target is provided that contains invalid JSON' do
      let(:targets) do
        [
          {
            name:    'tasks/invalid.json',
            content: '{"description": "Invalid Metadata", "version": "definitely the wrong type"}',
          },
        ]
      end

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first[:name],
          source:   'task-metadata-lint',
          state:    :failure,
          severity: 'error',
          message:  a_string_matching(%r{did not match the following type}i),
        )
        expect(return_value).to eq(1)
      end
    end

    context 'when targets are provided that contain valid and invalid JSON' do
      let(:targets) do
        [
          {
            name:    'tasks/invalid.json',
            content: '{"description": "Invalid Metadata", "version": "definitely the wrong type"}',
          },
          {
            name:    'tasks/valid.json',
            content: '{"description": "wow. so. valid.", "version": 1}',
          },
        ]
      end

      it 'adds events for all valid and invalid targets to the report' do
        expect(report).to receive(:add_event).with(
          file:     'tasks/invalid.json',
          source:   'task-metadata-lint',
          state:    :failure,
          severity: 'error',
          message:  a_string_matching(%r{did not match the following type}i),
        )
        expect(report).to receive(:add_event).with(
          file:     'tasks/valid.json',
          source:   'task-metadata-lint',
          state:    :passed,
          severity: 'ok',
        )
        expect(return_value).to eq(1)
      end
    end
  end
end
