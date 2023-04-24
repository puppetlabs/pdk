require 'spec_helper'
require 'pdk/validate/yaml/yaml_syntax_validator'

describe PDK::Validate::YAML::YAMLSyntaxValidator do
  let(:module_root) { File.join('path', 'to', 'test', 'module') }

  before do
    allow(PDK::Util).to receive(:module_root).and_return(module_root)
    allow(PDK::Util::Filesystem).to receive(:directory?).with(module_root).and_return(true)
  end

  describe '.spinner_text' do
    subject(:text) { described_class.new.spinner_text }

    it { is_expected.to match(/\AChecking YAML syntax/i) }
  end

  describe '.validate_target' do
    subject(:return_value) { described_class.new.validate_target(report, target[:name]) }

    let(:report) { PDK::Report.new }

    before do
      allow(PDK::Util::Filesystem).to receive(:directory?).with(target[:name]).and_return(target.fetch(:directory, false))
      allow(PDK::Util::Filesystem).to receive(:file?).with(target[:name]).and_return(target.fetch(:file, true))
      allow(PDK::Util::Filesystem).to receive(:readable?).with(target[:name]).and_return(target.fetch(:readable, true))
      allow(PDK::Util::Filesystem).to receive(:read_file).with(target[:name]).and_return(target.fetch(:content, ''))
    end

    context 'when a target is provided that is an unreadable file' do
      let(:target) { { name: '.sync.yml', readable: false } }

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: 'yaml-syntax',
                                                     state: :failure,
                                                     severity: 'error',
                                                     message: 'Could not be read.'
                                                   })
        expect(return_value).to eq(1)
      end
    end

    context 'when a target is provided that is not a file' do
      let(:target) { { name: 'a_directory.yml', file: false } }

      it 'skips the target' do
        expect(report).not_to receive(:add_event)
      end
    end

    context 'when a target is provided that contains valid YAML' do
      let(:target) { { name: '.sync.yml', content: "---\n  foo: bar" } }

      it 'adds a passing event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: 'yaml-syntax',
                                                     state: :passed,
                                                     severity: 'ok'
                                                   })
        expect(return_value).to eq(0)
      end
    end

    context 'when a target is provided that contains valid YAML with a symbol value' do
      let(:target) { { name: '.sync.yml', content: "---\n  foo: :bar" } }

      it 'adds a passing event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: 'yaml-syntax',
                                                     state: :passed,
                                                     severity: 'ok'
                                                   })
        expect(return_value).to eq(0)
      end
    end

    context 'when a target is provided that contains invalid YAML' do
      let(:target) { { name: '.sync.yaml', content: "---\n\tfoo: bar" } }

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: 'yaml-syntax',
                                                     state: :failure,
                                                     severity: 'error',
                                                     message: a_string_matching(/\Afound character that cannot start/),
                                                     line: 2,
                                                     column: 1
                                                   })
        expect(return_value).to eq(1)
      end
    end

    context 'when a target is provided that contains an unsupported class' do
      let(:target) { { name: 'file.yml', content: "--- !ruby/object:File {}\n" } }

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: target[:name],
                                                     source: 'yaml-syntax',
                                                     state: :failure,
                                                     severity: 'error',
                                                     message: a_string_matching(/unspecified class: file/i)
                                                   })
        expect(return_value).to eq(1)
      end
    end
  end
end
