require 'spec_helper'
require 'pdk/tests/unit'

describe PDK::Test::Unit do
  it 'has an invoke method' do
    expect(described_class.methods(false)).to include(:invoke)
  end

  describe '.parallel_with_no_tests?' do
    context 'when not parallel' do
      it 'is false' do
        result = {
          stderr: 'Pass files or folders to run',
          exit_code: 1,
        }

        expect(described_class.parallel_with_no_tests?(false, ['json_result'], result)).to be(false)
      end
    end
  end

  describe '.merge_json_results' do
    let(:duration) { 55 }
    let(:results) do
      [{ 'messages' => ['message 1', 'message 2'],
         'examples' => %w[example example example],
         'summary' => {
           'example_count' => 40,
           'failure_count' => 7,
           'pending_count' => 12,
           'duration' => 30,
         } },
       {
         'messages' => ['message 2', 'message 3'],
         'examples' => %w[example example example],
         'summary' => {
           'example_count' => 30,
           'failure_count' => 4,
           'pending_count' => 6,
           'duration' => 40,
         },
       }]
    end

    it 'successfully combines information' do
      json_result = described_class.merge_json_results(results, duration)

      expect(json_result['messages'].count).to eq(3)
      expect(json_result['examples'].count).to eq(6)
      expect(json_result['summary']['example_count']).to eq(70)
      expect(json_result['summary']['failure_count']).to eq(11)
      expect(json_result['summary']['pending_count']).to eq(18)
    end

    it 'assigns given duration to the result' do
      json_result = described_class.merge_json_results(results, duration)

      expect(json_result['summary']['duration']).to eq(duration)
    end
  end

  describe '.cmd' do
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/module')
    end

    context 'when run with parallel option' do
      it 'uses the parallel_spec rake task' do
        cmd = described_class.cmd(nil, parallel: true)

        expect(cmd.join('/')).to match(%r{bin/rake/parallel_spec})
      end
    end

    context 'when run without the parallel option' do
      it 'uses the spec rake task' do
        cmd = described_class.cmd(nil)

        expect(cmd.join('/')).to match(%r{bin/rake/spec})
      end
    end
  end

  describe '.parse_output' do
    let(:report) { PDK::Report.new }

    before(:each) do
      allow(report).to receive(:add_event).with(%r{message \d})
    end

    context 'with messages' do
      let(:json) { { 'messages' => ['message 1', 'message 2'] } }

      it 'prints the messages to stderr' do
        expect($stderr).to receive(:puts).twice
        described_class.parse_output(report, json)
      end
    end

    context 'with summary' do
      let(:json) do
        { 'summary' => {
          'example_count' => 30,
          'duration' => 32,
          'failure_count' => 2,
          'pending_count' => 6,
        } }
      end

      it 'prints the summary to stderr' do
        expect($stderr).to receive(:puts).once.with(%r{Evaluated 30 tests in 32 seconds})

        described_class.parse_output(report, json)
      end
    end
  end

  # Allow any_instance stubbing of Commands
  # rubocop:disable RSpec/AnyInstance
  describe '.list' do
    before(:each) do
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!)
      allow(PDK::Util::Bundler).to receive(:ensure_binstubs!)
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/module')
      allow_any_instance_of(PDK::CLI::Exec::Command).to receive(:execute!).and_return(stdout: rspec_json_output)
    end

    context 'with examples' do
      let(:rspec_json_output) do
        '{
          "examples": [
            { "id": "./path/to/test[1:1:1]",
              "full_description": "a bunch of useful descriptive words",
              "description": "descriptive words" }
          ]
        }'
      end

      it 'returns the id and full_description from the rspec output' do
        expected_result = [
          {
            id: './path/to/test[1:1:1]',
            full_description: 'a bunch of useful descriptive words',
          },
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

    before(:each) do
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!)
      allow(PDK::Util::Bundler).to receive(:ensure_binstubs!)
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/module')
      allow_any_instance_of(PDK::CLI::Exec::Command).to receive(:execute!).and_return(stdout: rspec_json_output, exit_code: -1)
      allow(described_class).to receive(:parse_output)
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
    end
  end
  # rubocop:enable RSpec/AnyInstance
end
