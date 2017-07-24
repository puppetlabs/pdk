require 'spec_helper'
require 'rubocop'
require 'ostruct'

shared_examples_for 'it sets the common options' do
  it 'sets the output format as JSON' do
    expect(command_args.first(2)).to eq(['--format', 'json'])
  end

  it 'only sets 1 output format' do
    expect(command_args.count('--format')).to eq(1)
  end

  it 'appends the targets to the command arguments' do
    expect(command_args.last(targets.count)).to eq(targets)
  end
end

describe PDK::Validate::Rubocop do
  let(:module_root) { File.join('path', 'to', 'test', 'module') }

  before(:each) do
    allow(PDK::Util).to receive(:module_root).and_return(module_root)
    allow(File).to receive(:directory?).with(module_root).and_return(true)
  end

  it 'defines the base validator attributes' do
    expect(described_class).to have_attributes(
      name:         'rubocop',
      cmd:          'rubocop',
      spinner_text: a_string_matching(%r{ruby code style}i),
    )
  end

  describe '.parse_targets' do
    subject(:target_files) { described_class.parse_targets(targets: targets) }

    context 'when given no targets' do
      let(:targets) { [] }

      it 'returns the module root' do
        expect(target_files).to eq([module_root])
      end
    end

    context 'when given specific targets' do
      let(:targets) { ['target1.rb', 'target2/'] }

      it 'returns the targets' do
        expect(target_files).to eq(targets)
      end
    end
  end

  describe '.parse_options' do
    subject(:command_args) { described_class.parse_options(options, targets) }

    let(:options) { {} }
    let(:targets) { %w[target1 target2] }

    context 'when auto-correct is enabled' do
      let(:options) { { auto_correct: true } }

      it_behaves_like 'it sets the common options'

      it 'includes the --auto-correct flag' do
        expect(command_args).to include('--auto-correct')
      end
    end

    context 'when auto-correct is disabled' do
      it_behaves_like 'it sets the common options'

      it 'does not include the --auto-correct flag' do
        expect(command_args).not_to include('--auto-correct')
      end
    end
  end

  describe '.parse_output' do
    subject(:parse_output) { described_class.parse_output(report, { stdout: rubocop_json }, []) }

    let(:rubocop_report) { RuboCop::Formatter::JSONFormatter.new(nil) }
    let(:rubocop_json) { rubocop_report.output_hash.to_json }
    let(:report) { PDK::Report.new }
    let(:test_file) { File.join(module_root, 'lib', 'test.rb') }

    def mock_offense(severity, message, cop_name, corrected, line, column)
      OpenStruct.new(
        severity:    OpenStruct.new(name: severity),
        message:     message,
        cop_name:    cop_name,
        corrected?:  corrected,
        line:        line,
        real_column: column,
        location:    OpenStruct.new(length: 0),
      )
    end

    context 'when rubocop generates bad JSON' do
      let(:rubocop_json) { '' }

      it 'does not add any events to the report' do
        expect(report).not_to receive(:add_event)

        parse_output
      end
    end

    context 'when rubocop has not tested any files' do
      it 'does not add any events to the report' do
        expect(report).not_to receive(:add_event)

        parse_output
      end
    end

    context 'when the rubocop output has no offenses for a file' do
      before(:each) do
        rubocop_report.file_finished(test_file, [])
      end

      it 'adds a passing event to the report' do
        expect(report).to receive(:add_event).with(
          file:     test_file,
          source:   described_class.name,
          state:    :passed,
          severity: :ok,
        )

        parse_output
      end
    end

    context 'when the rubocop output has an offense for a file' do
      let(:offenses) do
        [
          mock_offense('error', 'test message', 'Test/Cop', false, 1, 2),
        ]
      end

      before(:each) do
        rubocop_report.file_finished(test_file, offenses)
      end

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with(
          file:     test_file,
          source:   described_class.name,
          state:    :failure,
          severity: 'error',
          message:  'test message',
          line:     1,
          column:   2,
          test:     'Test/Cop',
        )

        parse_output
      end

      context 'when rubocop has corrected the offense' do
        let(:offenses) do
          [
            mock_offense('error', 'test message', 'Test/Cop', true, 1, 2),
          ]
        end

        it 'changes the severity of the event to "corrected"' do
          expect(report).to receive(:add_event).with(
            file:     test_file,
            source:   described_class.name,
            state:    :failure,
            severity: 'corrected',
            message:  'test message',
            line:     1,
            column:   2,
            test:     'Test/Cop',
          )

          parse_output
        end
      end
    end

    context 'when the rubocop output has information for multiple files' do
      let(:test_files) do
        {
          File.join(module_root, 'spec', 'spec_helper.rb') => [],
          File.join(module_root, 'lib', 'fail.rb')         => [
            mock_offense('error', 'correctable error', 'Test/Cop', true, 1, 2),
            mock_offense('warning', 'uncorrectable thing', 'Test/Cop2', false, 3, 4),
          ],
        }
      end

      before(:each) do
        test_files.each do |file, offenses|
          rubocop_report.file_finished(file, offenses)
        end
        allow(report).to receive(:add_event).with(anything)
      end

      it 'adds a passing event to the report for the file with no offenses' do
        expect(report).to receive(:add_event).with(
          file:     File.join(module_root, 'spec', 'spec_helper.rb'),
          source:   described_class.name,
          state:    :passed,
          severity: :ok,
        )

        parse_output
      end

      it 'adds a corrected failure event to the report for the file with offenses' do
        expect(report).to receive(:add_event).with(
          file:     File.join(module_root, 'lib', 'fail.rb'),
          source:   described_class.name,
          state:    :failure,
          severity: 'corrected',
          message:  'correctable error',
          line:     1,
          column:   2,
          test:     'Test/Cop',
        )

        parse_output
      end

      it 'adds a failure event to the report for the file with offenses' do
        expect(report).to receive(:add_event).with(
          file:     File.join(module_root, 'lib', 'fail.rb'),
          source:   described_class.name,
          state:    :failure,
          severity: 'warning',
          message:  'uncorrectable thing',
          line:     3,
          column:   4,
          test:     'Test/Cop2',
        )

        parse_output
      end
    end
  end
end
