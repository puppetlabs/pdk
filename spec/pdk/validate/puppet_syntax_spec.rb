require 'spec_helper'

describe PDK::Validate::PuppetSyntax do
  let(:module_root) { File.join('path', 'to', 'test', 'module') }

  before(:each) do
    allow(PDK::Util).to receive(:module_root).and_return(module_root)
    allow(File).to receive(:directory?).with(module_root).and_return(true)
  end

  it 'defines the base validator attributes' do
    expect(described_class).to have_attributes(
      name:         'puppet-syntax',
      cmd:          'puppet',
      spinner_text: a_string_matching(%r{puppet manifest syntax}i),
    )
  end

  it_behaves_like 'it accepts .pp targets'

  describe '.parse_options' do
    subject(:command_args) { described_class.parse_options(options, targets) }

    let(:options) { {} }
    let(:targets) { %w[target1 target2.pp] }

    it 'invokes `puppet parser validate`' do
      expect(command_args.first(2)).to eq(%w[parser validate])
    end

    it 'appends the targets to the command arguments' do
      expect(command_args.last(targets.count)).to eq(targets)
    end

    context 'when auto-correct is enabled' do
      let(:options) { { auto_correct: true } }

      it 'has no effect' do
        expect(command_args).to eq(%w[parser validate].concat(targets))
      end
    end
  end

  describe '.parse_output' do
    subject(:parse_output) do
      described_class.parse_output(report, { stderr: validate_output }, targets)
    end

    let(:report) { PDK::Report.new }
    let(:validate_output) do
      [
        mock_validate('fail.pp', 1, 2, 'test message', 'error'),
      ].join('')
    end
    let(:targets) { ['pass.pp', 'fail.pp'] }

    def mock_validate(file, line, column, message, severity)
      "#{severity}: #{message} at #{file}:#{line}:#{column}\n"
    end

    before(:each) do
      allow(report).to receive(:add_event)
    end

    context 'when the output contains no references to a target' do
      it 'adds a passing event for the target to the report' do
        expect(report).to receive(:add_event).with(
          file:     'pass.pp',
          source:   described_class.name,
          state:    :passed,
          severity: :ok,
        )

        parse_output
      end
    end

    context 'when the output contains a reference to a target' do
      it 'adds a failure event for the referenced target to the report' do
        expect(report).to receive(:add_event).with(
          file:     'fail.pp',
          source:   described_class.name,
          state:    :failure,
          message:  'test message',
          severity: 'error',
          line:     '1',
          column:   '2',
        )

        parse_output
      end
    end
  end
end
