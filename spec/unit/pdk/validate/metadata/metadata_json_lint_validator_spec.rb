require 'spec_helper'
require 'pdk/validate/metadata/metadata_json_lint_validator'

describe PDK::Validate::Metadata::MetadataJSONLintValidator do
  subject(:validator) { described_class.new }

  it 'defines the base validator attributes' do
    expect(validator).to have_attributes(
      name: 'metadata-json-lint',
      cmd: 'metadata-json-lint',
    )
  end

  describe '.spinner_text_for_targets' do
    subject(:spinner_text_for_targets) { validator.spinner_text_for_targets(targets) }

    context 'when given a relative path to the target' do
      let(:targets) { ['foo/metadata.json'] }

      it 'includes the path to the target in the spinner text' do
        expect(spinner_text_for_targets).to match(/checking module metadata style \(#{Regexp.escape(targets.first)}\)/i)
      end
    end

    context 'when given an absolute path to the target' do
      let(:targets) do
        if Gem.win_platform?
          ['C:/path/to/module/metadata.json']
        else
          ['/path/to/module/metadata.json']
        end
      end

      before do
        pwd = Gem.win_platform? ? 'C:/path/to/module' : '/path/to/module'
        allow(Pathname).to receive(:pwd).and_return(Pathname.new(pwd))
      end

      it 'includes the path to the target relative to the PWD in the spinner text' do
        expect(spinner_text_for_targets).to match(/checking module metadata style \(metadata\.json\)/i)
      end
    end
  end

  describe '.pattern' do
    it 'only contextually matches metadata.json files' do
      expect(validator).to receive(:contextual_pattern).with('metadata.json') # rubocop:disable RSpec/SubjectStub This is fine
      validator.pattern
    end
  end

  describe '.parse_options' do
    subject(:command_args) { validator.parse_options(targets) }

    let(:targets) { ['target1', 'target2.json'] }

    it 'sets the output format as JSON' do
      expect(command_args.join(' ')).to match(/--format json/)
    end

    it 'enables strict dependency check' do
      expect(command_args).to include('--strict-dependencies')
    end

    it 'appends the targets to the command arguments' do
      expect(command_args.last(targets.count)).to eq(targets)
    end
  end

  describe '.parse_output' do
    subject(:parse_output) do
      validator.parse_output(report, { stdout: metadata_json_lint_output }, targets)
    end

    let(:report) { PDK::Report.new }
    let(:metadata_json_lint_output) { { result: 'something', errors: errors, warnings: warnings }.to_json }
    let(:targets) { ['metadata.json'] }
    let(:errors) { [] }
    let(:warnings) { [] }

    context 'when passed multiple targets' do
      let(:targets) { ['metadata.json', 'another.json'] }

      it 'raises an ArgumentError' do
        expect { parse_output }.to raise_error(ArgumentError, a_string_matching(/more than 1 target provided/i))
      end
    end

    context 'when metadata-json-lint generates no output' do
      let(:metadata_json_lint_output) { '' }

      it 'adds a passing event for the target to the report' do
        expect(report).to receive(:add_event).with({
                                                     file: targets.first,
                                                     source: validator.name,
                                                     state: :passed,
                                                     severity: :ok,
                                                   })

        parse_output
      end
    end

    context 'when metadata-json-lint generates bad JSON' do
      let(:metadata_json_lint_output) { 'some unhandled error' }

      it 'adds an error event for the target to the report' do
        expect do
          parse_output
        end.to raise_error(PDK::Validate::ParseOutputError, 'some unhandled error')
      end
    end

    context 'when metadata-json-lint finds problems in the target' do
      let(:errors) { [{ 'msg' => 'some error', 'check' => 'error-check' }] }
      let(:warnings) { [{ 'msg' => 'some warning', 'check' => 'warning-check' }] }

      it 'adds a failure event to the report for each error' do
        allow(report).to receive(:add_event)

        errors.each do |error|
          expect(report).to receive(:add_event).with({
                                                       file: targets.first,
                                                       source: validator.name,
                                                       message: error['msg'],
                                                       test: error['check'],
                                                       severity: 'error',
                                                       state: :failure,
                                                     })
        end

        parse_output
      end

      it 'adds a failure event to the report for each warning' do
        allow(report).to receive(:add_event)

        warnings.each do |warning|
          expect(report).to receive(:add_event).with({
                                                       file: targets.first,
                                                       source: validator.name,
                                                       message: warning['msg'],
                                                       test: warning['check'],
                                                       severity: 'warning',
                                                       state: :failure,
                                                     })
        end

        parse_output
      end
    end
  end
end
