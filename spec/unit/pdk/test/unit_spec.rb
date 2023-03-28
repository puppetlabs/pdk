require 'spec_helper'
require 'pdk/tests/unit'

describe PDK::Test::Unit do
  it 'has an invoke method' do
    expect(described_class.methods(false)).to include(:invoke)
  end

  describe '.rake_bin' do
    subject { described_class.rake_bin }

    before do
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/module')
    end

    it { is_expected.to eq(File.join('/path/to/module', 'bin', 'rake')) }
  end

  describe '.parallel_with_no_tests?' do
    subject { described_class.parallel_with_no_tests?(ran_in_parallel, json_result, cmd_result) }

    let(:json_result) { [] }
    let(:cmd_result) { { stderr: '', stdout: '', exit_code: 1 } }

    context 'when not run in parallel' do
      let(:ran_in_parallel) { false }

      it { is_expected.to be_falsey }
    end

    context 'when run in parallel' do
      let(:ran_in_parallel) { true }

      context 'and no tests (puppetlabs_spec_helper <= 2.5.0)' do
        let(:cmd_result) do
          { stderr: 'Pass files or folders to run', stdout: '', exit_code: 1 }
        end

        it { is_expected.to be_truthy }
      end

      context 'and no tests (puppetlabs_spec_helper >= 2.5.1)' do
        let(:cmd_result) do
          { stderr: 'No files for parallel_spec to run against', stdout: '', exit_code: 0 }
        end

        it { is_expected.to be_truthy }
      end

      context 'and there are tests' do
        let(:json_result) { ['something'] }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '.setup' do
    before do
      mock_result = { stdout: 'some output', stderr: 'some error', exit_code: exit_code }
      allow(described_class).to receive(:rake).with('spec_prep', any_args).and_return(mock_result)
    end

    context 'when the rake task succeeds' do
      let(:exit_code) { 0 }

      it 'does not raise an error' do
        expect do
          described_class.setup
        end.not_to raise_error
      end
    end

    context 'when the rake task fails' do
      let(:exit_code) { 1 }

      it 'prints the output of the command to STDERR and raises a FatalError' do
        expect($stderr).to receive(:puts).with('').twice
        expect($stderr).to receive(:puts).with('some output')
        expect($stderr).to receive(:puts).with('some error')
        expect(logger).to receive(:error).with(a_string_matching(/spec_prep rake task failed/))
        expect(described_class).to receive(:tear_down)

        expect do
          described_class.setup
        end.to raise_error(PDK::CLI::FatalError, /failed to prepare to run the unit tests/i)
      end
    end
  end

  describe '.tear_down' do
    before do
      mock_result = { stdout: 'some output', stderr: 'some error', exit_code: exit_code }
      allow(described_class).to receive(:rake).with('spec_clean', any_args).and_return(mock_result)
    end

    context 'when the rake task succeeds' do
      let(:exit_code) { 0 }

      it 'does not raise an error' do
        expect do
          described_class.tear_down
        end.not_to raise_error
      end
    end

    context 'when the rake task fails' do
      let(:exit_code) { 1 }

      it 'prints the output of the command to STDERR and raises a FatalError' do
        expect($stderr).to receive(:puts).with('').twice
        expect($stderr).to receive(:puts).with('some output')
        expect($stderr).to receive(:puts).with('some error')
        expect(logger).to receive(:error).with(a_string_matching(/spec_clean rake task failed/))

        expect do
          described_class.tear_down
        end.to raise_error(PDK::CLI::FatalError, /failed to clean up after running unit tests/i)
      end
    end
  end

  describe '.merge_json_results' do
    let(:results) do
      [{ 'messages' => ['message 1', 'message 2'],
         'examples' => ['example', 'example', 'example'],
         'summary' => {
           'example_count' => 40,
           'failure_count' => 7,
           'pending_count' => 12,
           'duration' => 30
         } },
       {
         'messages' => ['message 2', 'message 3'],
         'examples' => ['example', 'example', 'example'],
         'summary' => {
           'example_count' => 30,
           'failure_count' => 4,
           'pending_count' => 6,
           'duration' => 40
         }
       }]
    end

    it 'successfully combines information' do
      json_result = described_class.merge_json_results(results)

      expect(json_result['messages'].count).to eq(3)
      expect(json_result['examples'].count).to eq(6)
      expect(json_result['summary']['example_count']).to eq(70)
      expect(json_result['summary']['failure_count']).to eq(11)
      expect(json_result['summary']['pending_count']).to eq(18)
    end
  end

  describe '.cmd' do
    before do
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/module')
    end

    context 'when run with parallel option' do
      it 'uses the parallel_spec rake task' do
        cmd = described_class.cmd(nil, parallel: true)

        expect(cmd).to eq('parallel_spec_standalone')
      end
    end

    context 'when run without the parallel option' do
      it 'uses the spec rake task' do
        cmd = described_class.cmd(nil)

        expect(cmd).to eq('spec_standalone')
      end
    end

    context 'when run with tests option' do
      it 'passes file paths to rake' do
        cmd = described_class.cmd('/path/to/test1,/path/to/test2')

        expect(cmd).to eq('spec_standalone[/path/to/test1,/path/to/test2]')
      end
    end
  end

  describe '.parse_output' do
    let(:report) { PDK::Report.new }
    let(:duration) { 4.123 }

    before do
      allow(report).to receive(:add_event).with(/message \d/)
    end

    context 'with messages' do
      let(:json) { { 'messages' => ['message 1', 'message 2'] } }

      it 'prints the messages to stderr' do
        expect($stderr).to receive(:puts).twice
        described_class.parse_output(report, json, duration)
      end
    end

    context 'with summary' do
      let(:json) do
        { 'summary' => {
          'example_count' => 30,
          'duration' => 32,
          'failure_count' => 2,
          'pending_count' => 6
        } }
      end

      after do
        described_class.parse_output(report, json, duration)
      end

      it 'prints the wall time of the rspec run instead of the rspec evaluation duration' do
        expect($stderr).to receive(:puts).once.with(%r{#{Regexp.escape(duration.to_s)} seconds})
        expect($stderr).not_to receive(:puts).with(%r{#{Regexp.escape(json['duration'].to_s)} seconds})
      end

      it 'prints the summary to stderr' do
        expect($stderr).to receive(:puts).once.with(/Evaluated 30 tests in 4\.123 seconds/)
      end
    end
  end

  # Allow any_instance stubbing of Commands
  # rubocop:disable RSpec/AnyInstance
  describe '.list' do
    before do
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!)
      allow(PDK::Util::Bundler).to receive(:ensure_binstubs!)
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/module')
      allow_any_instance_of(PDK::CLI::Exec::Command).to receive(:execute!).and_return(stdout: rspec_json_output)
    end

    context 'with examples' do
      let(:rspec_json_output) do
        '{
          "examples": [
            { "file_path": "./path/to/test",
              "id": "./path/to/test[1:1:1]",
              "full_description": "a bunch of useful descriptive words",
              "description": "descriptive words" }
          ]
        }'
      end

      it 'returns the id and full_description from the rspec output' do
        expected_result = [
          {
            file_path: './path/to/test',
            id: './path/to/test[1:1:1]',
            full_description: 'a bunch of useful descriptive words'
          }
        ]

        expect(described_class.list).to eq(expected_result)
      end
    end

    context 'without examples' do
      let(:rspec_json_output) do
        '{
          "messages": [
            "No examples found."
          ],
          "examples": []
        }'
      end

      it 'returns an empty array' do
        expect(described_class.list).to eq([])
      end
    end
  end

  describe '.invoke' do
    let(:report) { PDK::Report.new }
    let(:rspec_json_output) { '{}' }

    before do
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!)
      allow(PDK::Util::Bundler).to receive(:ensure_binstubs!)
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/module')
      allow(described_class).to receive(:setup)
      allow(described_class).to receive(:tear_down)
      allow_any_instance_of(PDK::CLI::Exec::Command).to receive(:execute!).and_return(stdout: rspec_json_output, exit_code: -1)
      allow(described_class).to receive(:parse_output)
    end

    context 'when running interactively' do
      subject(:exit_code) do
        described_class.invoke(report, options)
      end

      before do
        allow(PDK::CLI::Exec::InteractiveCommand).to receive(:new)
          .and_return(command)
        allow(command).to receive(:execute!).and_return(exit_code: 0)
      end

      let(:options) { { interactive: true } }

      let(:command) do
        instance_double(
          PDK::CLI::Exec::InteractiveCommand,
          :context= => true,
          :environment= => true
        )
      end

      it 'runs the rake task interactively' do
        expect(exit_code).to eq(0)
      end

      context 'when --verbose is not passed' do
        it 'uses the progress formatter' do
          expect(command).to receive(:environment=).with(include('CI_SPEC_OPTIONS' => '--format progress'))

          exit_code
        end
      end

      context 'when --verbose is passed' do
        let(:options) { super().merge(verbose: true) }

        it 'uses the documentation formatter' do
          expect(command).to receive(:environment=).with(include('CI_SPEC_OPTIONS' => '--format documentation'))
          exit_code
        end
      end
    end

    context 'in parallel without examples' do
      let(:rspec_json_output) do
        'Pass files or folders to run'
      end

      it "returns 0 and doesn't error" do
        expect(described_class).to receive(:parallel_with_no_tests?).and_return(true)

        exit_code = -1
        expect { exit_code = described_class.invoke(report, tests: 'a_test_spec.rb') }.not_to raise_exception
        expect(exit_code).to eq(0)
      end
    end

    context 'configurable fixture cleaning' do
      after do
        described_class.invoke(report, options)
      end

      let(:rspec_json_output) do
        '{
          "examples":
          [
            {
              "id": "./spec/fixtures/modules/testmod/spec/classes/testmod_spec.rb[1:3:1]",
              "status": "passed",
              "pending_message": null
            }
          ],
          "summary": {
            "duration": 0.295112,
            "example_count": 1,
            "failure_count": 0,
            "pending_count": 0
          }
        }'
      end

      context 'when enabled' do
        let(:options) do
          {
            'clean-fixtures': true,
            tests: 'testmod_spec.rb'
          }
        end

        it 'calls tear_down' do
          expect(described_class).to receive(:tear_down)
        end
      end

      context 'when disabled' do
        let(:options) do
          {
            tests: 'testmod_spec.rb'
          }
        end

        it 'does not call tear_down' do
          expect(described_class).not_to receive(:tear_down)
        end
      end
    end

    context 'in parallel without examples' do
      let(:rspec_json_output) do
        '{
          "examples":
          [
            {
              "id": "./spec/fixtures/modules/testmod/spec/classes/testmod_spec.rb[1:3:1]",
              "status": "passed",
              "pending_message": null
            }
          ],
          "summary": {
            "duration": 0.295112,
            "example_count": 1,
            "failure_count": 0,
            "pending_count": 0
          }
        }
        {
          "examples":
          [
            {
              "id": "./spec/fixtures/modules/testmod/spec/classes/testmod_spec.rb[1:3:1]",
              "status": "passed",
              "pending_message": null
            }
          ],
          "summary": {
            "duration": 0.295112,
            "example_count": 1,
            "failure_count": 0,
            "pending_count": 0
          }
        }'
      end

      it 'returns 0' do
        expect(PDK::Util).not_to receive(:find_first_json_in)

        expect(described_class.invoke(report, parallel: true, tests: 'a_test_spec.rb')).to eq(-1)
      end
    end

    context 'with examples' do
      let(:rspec_json_output) do
        '{
          "examples":
          [
            {
              "id": "./spec/fixtures/modules/testmod/spec/classes/testmod_spec.rb[1:3:1]",
              "status": "passed",
              "pending_message": null
            }
          ],
          "summary": {
            "duration": 0.295112,
            "example_count": 1,
            "failure_count": 0,
            "pending_count": 0
          }
        }'
      end

      it 'executes and parses output' do
        expect(described_class).to receive(:parse_output).once
        exit_code = described_class.invoke(report, tests: 'a_test_spec.rb')
        expect(exit_code).to eq(-1)
      end

      context 'with Windows paths' do
        it 'uses forward slashes to invoke rake' do
          expect(described_class).to receive(:parse_output).once
          expect(described_class).to receive(:rake).with(%r{path/a_test_spec.rb}, anything, anything).and_call_original
          exit_code = described_class.invoke(report, tests: 'path\\a_test_spec.rb')
          expect(exit_code).to eq(-1)
        end
      end
    end
  end
  # rubocop:enable RSpec/AnyInstance
end
