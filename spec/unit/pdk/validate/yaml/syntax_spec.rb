require 'spec_helper'

describe PDK::Validate::YAML::Syntax do
  let(:module_root) { File.join('path', 'to', 'test', 'module') }

  before(:each) do
    allow(PDK::Util).to receive(:module_root).and_return(module_root)
    allow(File).to receive(:directory?).with(module_root).and_return(true)
  end

  describe '.spinner_text' do
    subject(:text) { described_class.spinner_text }

    it { is_expected.to match(%r{\AChecking YAML syntax}i) }
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
        expect(report).to receive(:add_event).with(
          file:     module_root,
          source:   'yaml-syntax',
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
          { name: '.sync.yml', readable: false },
        ]
      end

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first[:name],
          source:   'yaml-syntax',
          state:    :failure,
          severity: 'error',
          message:  'Could not be read.',
        )
        expect(return_value).to eq(1)
      end
    end

    context 'when a target is provided that contains valid YAML' do
      let(:targets) do
        [
          { name: '.sync.yml', content: "---\n  foo: bar" },
        ]
      end

      it 'adds a passing event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first[:name],
          source:   'yaml-syntax',
          state:    :passed,
          severity: 'ok',
        )
        expect(return_value).to eq(0)
      end
    end

    context 'when a target is provided that contains invalid YAML' do
      let(:targets) do
        [
          { name: '.sync.yaml', content: "---\n\tfoo: bar" },
        ]
      end

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first[:name],
          source:   'yaml-syntax',
          state:    :failure,
          severity: 'error',
          message:  a_string_matching(%r{\Afound character that cannot start}),
          line:     2,
          column:   1,
        )
        expect(return_value).to eq(1)
      end
    end

    context 'when a target is provided that contains an unsupported class' do
      let(:targets) do
        [
          { name: 'file.yml', content: "--- !ruby/object:File {}\n" },
        ]
      end

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first[:name],
          source:   'yaml-syntax',
          state:    :failure,
          severity: 'error',
          message:  a_string_matching(%r{unspecified class: file}i),
        )
        expect(return_value).to eq(1)
      end
    end

    context 'when targets are provided that contain valid and invalid YAML' do
      let(:targets) do
        [
          { name: 'invalid/data.yml', content: "---\n\tfoo: bar" },
          { name: '.sync.yml', content: "---\n  foo: bar" },
        ]
      end

      it 'adds events for all valid targets to the report' do
        expect(report).to receive(:add_event).with(
          file:     'invalid/data.yml',
          source:   'yaml-syntax',
          state:    :failure,
          severity: 'error',
          message:  a_string_matching(%r{\Afound character that cannot start}),
          line:     2,
          column:   1,
        )
        expect(report).to receive(:add_event).with(
          file:     '.sync.yml',
          source:   'yaml-syntax',
          state:    :passed,
          severity: 'ok',
        )
        expect(return_value).to eq(1)
      end
    end
  end
end
