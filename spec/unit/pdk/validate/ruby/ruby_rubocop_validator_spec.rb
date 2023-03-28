require 'spec_helper'
require 'rubocop'
require 'ostruct'
require 'pdk/validate/ruby/ruby_rubocop_validator'

shared_examples_for 'it sets the common rubocop options' do
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

describe PDK::Validate::Ruby::RubyRubocopValidator do
  subject(:validator) { described_class.new(validator_context, options) }

  let(:validator_context) { nil }
  let(:options) { {} }

  it 'defines the ExternalCommandValidator attributes' do
    expect(validator).to have_attributes(
      name: 'rubocop',
      cmd: 'rubocop',
    )
    expect(validator.spinner_text_for_targets(nil)).to match(%r{ruby code style}i)
  end

  describe '.pattern' do
    context 'in a Puppet Module' do
      it 'only matches ruby files' do
        expect(validator.pattern).to eq('**/**.rb')
      end
    end

    context 'in a Control Repo' do
      let(:context_root) { File.join(FIXTURES_DIR, 'control_repo') }
      let(:validator_context) { PDK::Context::ControlRepo.new(context_root, context_root) }

      it 'only matches ruby files and Pupeptfile' do
        expect(validator.pattern).to eq(['Puppetfile', '**/**.rb'])
      end
    end
  end

  describe '.pattern_ignore' do
    it 'does not ignore any files' do
      expect(validator.pattern_ignore).to be_nil
    end
  end

  describe '.parse_options' do
    subject(:command_args) { validator.parse_options(targets) }

    let(:targets) { ['target1', 'target2'] }

    context 'when auto-correct is enabled' do
      let(:options) { { auto_correct: true } }

      it_behaves_like 'it sets the common rubocop options'

      it 'includes the --auto-correct flag' do
        expect(command_args).to include('--auto-correct')
      end
    end

    context 'when auto-correct is disabled' do
      it_behaves_like 'it sets the common rubocop options'

      it 'does not include the --auto-correct flag' do
        expect(command_args).not_to include('--auto-correct')
      end
    end
  end

  describe '.parse_output' do
    subject(:parse_output) { validator.parse_output(report, { stdout: rubocop_json }, []) }

    let(:rubocop_report) { RuboCop::Formatter::JSONFormatter.new(nil) }
    let(:rubocop_json) { rubocop_report.output_hash.to_json }
    let(:report) { PDK::Report.new }
    let(:test_file) { File.join('lib', 'test.rb') }

    def mock_offense(severity, message, cop_name, corrected, line, column)
      OpenStruct.new(
        severity: OpenStruct.new(name: severity),
        message: message,
        cop_name: cop_name,
        corrected?: corrected,
        line: line,
        last_line: line,
        real_column: column,
        last_column: column,
        location: OpenStruct.new(length: 0),
      )
    end

    context 'when rubocop generates bad JSON' do
      let(:rubocop_json) { 'this is not JSON' }

      it 'does not add any events to the report' do
        expect {
          parse_output
        }.to raise_error(PDK::Validate::ParseOutputError, 'this is not JSON')
      end
    end

    context 'when rubocop has not tested any files' do
      it 'does not add any events to the report' do
        expect(report).not_to receive(:add_event)

        parse_output
      end
    end

    context 'when the rubocop output has no offenses for a file' do
      before do
        rubocop_report.file_finished(test_file, [])
      end

      it 'adds a passing event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: test_file,
                                                     source: validator.name,
                                                     state: :passed,
                                                     severity: :ok,
                                                   })

        parse_output
      end
    end

    context 'when the rubocop output has an offense for a file' do
      let(:offenses) do
        [
          mock_offense('error', 'test message', 'Test/Cop', false, 1, 2),
        ]
      end

      before do
        rubocop_report.file_finished(test_file, offenses)
      end

      it 'adds a failure event to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: test_file,
                                                     source: validator.name,
                                                     state: :failure,
                                                     severity: 'error',
                                                     message: 'test message',
                                                     line: 1,
                                                     column: 2,
                                                     test: 'Test/Cop',
                                                   })

        parse_output
      end

      context 'when rubocop has corrected the offense' do
        let(:offenses) do
          [
            mock_offense('error', 'test message', 'Test/Cop', true, 1, 2),
          ]
        end

        it 'changes the severity of the event to "corrected"' do
          expect(report).to receive(:add_event).with({
                                                       file: test_file,
                                                       source: validator.name,
                                                       state: :failure,
                                                       severity: 'corrected',
                                                       message: 'test message',
                                                       line: 1,
                                                       column: 2,
                                                       test: 'Test/Cop',
                                                     })

          parse_output
        end
      end
    end

    context 'when the rubocop output has information for multiple files' do
      let(:test_files) do
        {
          File.join('spec', 'spec_helper.rb') => [],
          File.join('lib', 'fail.rb') => [
            mock_offense('error', 'correctable error', 'Test/Cop', true, 1, 2),
            mock_offense('warning', 'uncorrectable thing', 'Test/Cop2', false, 3, 4),
          ],
        }
      end

      before do
        test_files.each do |file, offenses|
          rubocop_report.file_finished(file, offenses)
        end
        allow(report).to receive(:add_event).with(anything)
      end

      it 'adds a passing event to the report for the file with no offenses' do
        expect(report).to receive(:add_event).with({
                                                     file: File.join('spec', 'spec_helper.rb'),
                                                     source: validator.name,
                                                     state: :passed,
                                                     severity: :ok,
                                                   })

        parse_output
      end

      it 'adds a corrected failure event to the report for the file with offenses' do
        expect(report).to receive(:add_event).with({
                                                     file: File.join('lib', 'fail.rb'),
                                                     source: validator.name,
                                                     state: :failure,
                                                     severity: 'corrected',
                                                     message: 'correctable error',
                                                     line: 1,
                                                     column: 2,
                                                     test: 'Test/Cop',
                                                   })

        parse_output
      end

      it 'adds a failure event to the report for the file with offenses' do
        expect(report).to receive(:add_event).with({
                                                     file: File.join('lib', 'fail.rb'),
                                                     source: validator.name,
                                                     state: :failure,
                                                     severity: 'warning',
                                                     message: 'uncorrectable thing',
                                                     line: 3,
                                                     column: 4,
                                                     test: 'Test/Cop2',
                                                   })

        parse_output
      end
    end
  end
end
