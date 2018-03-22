# frozen_string_literal: true

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

    before(:each) do
      allow(Gem).to receive(:win_platform?).and_return(false)
    end

    it 'invokes `puppet parser validate`' do
      expect(command_args.first(2)).to eq(%w[parser validate])
    end

    it 'appends the targets to the command arguments' do
      expect(command_args.last(targets.count)).to eq(targets)
    end

    context 'when auto-correct is enabled' do
      let(:options) { { auto_correct: true } }

      it 'has no effect' do
        expect(command_args).to eq(%w[parser validate --config /dev/null].concat(targets))
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
        mock_validate('fail.pp', 1, 2, 'test message 1', 'error'),
        mock_validate('fail.pp', 1, nil, 'test message 2', 'error'),
        mock_validate('fail.pp', nil, nil, 'test message 3', 'error'),
        mock_validate(nil, 1, nil, 'test message 4', 'error'),
        "error: 5.3.4 test-type-1 (file: warning.pp, line: 34, column: 45)\n",
        "error: 5.3.4 test-type-2 (file: warning.pp, line: 34)\n",
        "error: 5.3.4 test-type-3 (line: 34, column: 45)\n",
        "error: 5.3.4 test-type-4 (line: 34)\n",
        "error: 5.3.4 test-type-5 (file: warning.pp)\n",
        "error: language validaton logged 2 errors. giving up\n",
      ].join('')
    end
    let(:targets) { ['pass.pp', 'fail.pp'] }

    def mock_validate(file, line, column, message, severity)
      output = "#{severity}: #{message}"
      if file && line && column
        output += " at #{file}:#{line}:#{column}\n"
      elsif file && line
        output += " at #{file}:#{line}\n"
      elsif line
        output += " at line #{line}\n"
      elsif file
        output += " in #{file}\n"
      end

      output
    end

    before(:each) do
      allow(report).to receive(:add_event)
    end

    after(:each) do
      parse_output
    end

    context 'when the output contains no references to a target' do
      it 'adds a passing event for the target to the report' do
        expect(report).to receive(:add_event).with(
          file:     'pass.pp',
          source:   described_class.name,
          state:    :passed,
          severity: :ok,
        )
      end
    end

    context 'with Puppet <= 5.3.3' do
      it 'handles syntax error locations with a file, line, and column' do
        expect(report).to receive(:add_event).with(
          file:     'fail.pp',
          source:   described_class.name,
          state:    :failure,
          message:  'test message 1',
          severity: 'error',
          column:   '2',
          line:     '1',
        )
      end

      it 'handles syntax error locations with a file and line' do
        expect(report).to receive(:add_event).with(
          file:     'fail.pp',
          source:   described_class.name,
          state:    :failure,
          message:  'test message 2',
          severity: 'error',
          line:     '1',
        )
      end

      it 'handles syntax error locations with a file' do
        expect(report).to receive(:add_event).with(
          file:     'fail.pp',
          source:   described_class.name,
          state:    :failure,
          message:  'test message 3',
          severity: 'error',
        )
      end

      it 'handles syntax error locations with a line' do
        expect(report).to receive(:add_event).with(
          source:   described_class.name,
          state:    :failure,
          message:  'test message 4',
          severity: 'error',
          line:     '1',
        )
      end
    end

    context 'with Puppet >= 5.3.4' do
      it 'handles syntax error locations with a file, line, and column' do
        expect(report).to receive(:add_event).with(
          file:     'warning.pp',
          source:   described_class.name,
          state:    :failure,
          message:  '5.3.4 test-type-1',
          severity: 'error',
          column:   '45',
          line:     '34',
        )
      end

      it 'handles syntax error locations with a file and line' do
        expect(report).to receive(:add_event).with(
          file:     'warning.pp',
          source:   described_class.name,
          state:    :failure,
          message:  '5.3.4 test-type-2',
          severity: 'error',
          line:     '34',
        )
      end

      it 'handles syntax error locations with a line and column' do
        expect(report).to receive(:add_event).with(
          source:   described_class.name,
          state:    :failure,
          message:  '5.3.4 test-type-3',
          severity: 'error',
          column:   '45',
          line:     '34',
        )
      end

      it 'handles syntax error locations with a line' do
        expect(report).to receive(:add_event).with(
          source:   described_class.name,
          state:    :failure,
          message:  '5.3.4 test-type-4',
          severity: 'error',
          line:     '34',
        )
      end

      it 'handles syntax error locations with a file' do
        expect(report).to receive(:add_event).with(
          file:     'warning.pp',
          source:   described_class.name,
          state:    :failure,
          message:  '5.3.4 test-type-5',
          severity: 'error',
        )
      end
    end
  end

  describe '.null_file' do
    subject { described_class.null_file }

    context 'on a Windows host' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(true)
      end

      it { is_expected.to eq('NUL') }
    end

    context 'on a POSIX host' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(false)
      end

      it { is_expected.to eq('/dev/null') }
    end
  end
end
