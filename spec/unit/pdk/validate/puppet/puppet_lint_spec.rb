require 'spec_helper'
require 'pdk/validate/puppet/puppet_lint'

shared_examples_for 'it sets the common puppet-lint options' do
  it 'sets the output format as JSON' do
    expect(command_args.first).to eq('--json')
  end

  it 'sets the autoload layout plugin to ignore the top-most directory' do
    expect(command_args[1]).to eq('--relative')
  end

  it 'appends the targets to the command arguments' do
    expect(command_args.last(targets.count)).to eq(targets)
  end
end

describe PDK::Validate::PuppetLint do
  let(:module_root) { File.join('path', 'to', 'test', 'module') }

  before(:each) do
    allow(PDK::Util).to receive(:module_root).and_return(module_root)
    allow(PDK::Util::Filesystem).to receive(:directory?).with(module_root).and_return(true)
  end

  it 'defines the base validator attributes' do
    expect(described_class).to have_attributes(
      name:         'puppet-lint',
      cmd:          'puppet-lint',
      spinner_text: a_string_matching(%r{puppet manifest style}i),
    )
  end

  it_behaves_like 'it accepts .pp targets'

  describe '.parse_options' do
    subject(:command_args) { described_class.parse_options(options, targets) }

    let(:options) { {} }
    let(:targets) { %w[target1 target2.pp] }

    context 'when auto-correct is enabled' do
      let(:options) { { auto_correct: true } }

      it_behaves_like 'it sets the common puppet-lint options'

      it 'includes the --fix flag' do
        expect(command_args).to include('--fix')
      end
    end

    context 'when auto-correct is disabled' do
      it_behaves_like 'it sets the common puppet-lint options'

      it 'does not include the --fix flag' do
        expect(command_args).not_to include('--fix')
      end
    end
  end

  describe '.parse_output' do
    subject(:parse_output) do
      described_class.parse_output(report, { stdout: lint_output }, targets)
    end

    let(:targets) { [] }
    let(:lint_output) { offenses.to_json }
    let(:offenses) { [] }
    let(:report) { PDK::Report.new }

    def mock_lint(path, line, column, message, check, kind)
      {
        'path'    => path,
        'line'    => line.to_s,
        'column'  => column.to_s,
        'message' => message,
        'check'   => check,
        'kind'    => kind,
      }
    end

    context 'when puppet-lint generates bad JSON' do
      let(:lint_output) { 'this is not JSON' }

      it 'adds no events to the report' do
        expect {
          parse_output
        }.to raise_error(PDK::Validate::ParseOutputError, 'this is not JSON')
      end
    end

    context 'when puppet-lint has no offenses for a file' do
      let(:targets) { ['target1'] }

      it 'adds a passing event for the file to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first,
          source:   described_class.name,
          severity: 'ok',
          state:    :passed,
        )

        parse_output
      end
    end

    context 'when puppet-lint has an offense for a file' do
      let(:targets) { ['target1'] }
      let(:offenses) do
        [
          mock_lint(targets.first, 1, 2, 'test message', 'test_check', 'warning'),
        ]
      end

      it 'adds a failure event for the file to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first,
          source:   described_class.name,
          line:     '1',
          column:   '2',
          message:  'test message',
          test:     'test_check',
          severity: 'warning',
          state:    :failure,
        )

        parse_output
      end

      context 'when puppet-lint has corrected the offense' do
        let(:offenses) do
          [
            mock_lint(targets.first, 1, 2, 'test message', 'test_check', 'fixed'),
          ]
        end

        it 'adds a failure event for the file to the report with the corrected severity' do
          expect(report).to receive(:add_event).with(
            file:     targets.first,
            source:   described_class.name,
            line:     '1',
            column:   '2',
            message:  'test message',
            test:     'test_check',
            severity: 'corrected',
            state:    :failure,
          )

          parse_output
        end
      end
    end

    context 'when puppet-lint generates output for multiple files' do
      let(:targets) { %w[target1 target2 target3] }
      let(:offenses) do
        [
          mock_lint('target1', 1, 2, 'test message 1', 'test_check_1', 'warning'),
          mock_lint('target1', 5, 6, 'test message 2', 'test_check_2', 'fixed'),
          mock_lint('target3', 3, 4, 'test message 3', 'test_check_3', 'error'),
        ]
      end

      before(:each) do
        allow(report).to receive(:add_event)
      end

      it 'adds a passing event to the report for the file with no offenses' do
        expect(report).to receive(:add_event).with(
          file:     'target2',
          source:   described_class.name,
          state:    :passed,
          severity: 'ok',
        )

        parse_output
      end

      it 'adds failure events to the report for the files with offenses' do
        expect(report).to receive(:add_event).with(
          file:     'target1',
          source:   described_class.name,
          line:     '1',
          column:   '2',
          message:  'test message 1',
          test:     'test_check_1',
          severity: 'warning',
          state:    :failure,
        )

        expect(report).to receive(:add_event).with(
          file:     'target1',
          source:   described_class.name,
          line:     '5',
          column:   '6',
          message:  'test message 2',
          test:     'test_check_2',
          severity: 'corrected',
          state:    :failure,
        )

        expect(report).to receive(:add_event).with(
          file:     'target3',
          source:   described_class.name,
          line:     '3',
          column:   '4',
          message:  'test message 3',
          test:     'test_check_3',
          severity: 'error',
          state:    :failure,
        )

        parse_output
      end
    end
  end
end
