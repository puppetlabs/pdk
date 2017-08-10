require 'spec_helper'

describe PDK::Validate::MetadataJSONLint do
  let(:module_root) { File.join('path', 'to', 'test', 'module') }

  before(:each) do
    allow(PDK::Util).to receive(:module_root).and_return(module_root)
    allow(File).to receive(:directory?).with(module_root).and_return(true)
  end

  it 'defines the base validator attributes' do
    expect(described_class).to have_attributes(
      name: 'metadata-json-lint',
      cmd:  'metadata-json-lint',
    )
  end

  describe '.spinner_text' do
    subject(:spinner_text) { described_class.spinner_text(targets) }

    context 'when given a relative path to the target' do
      let(:targets) { ['foo/metadata.json'] }

      it 'includes the path to the target in the spinner text' do
        expect(spinner_text).to match(%r{checking metadata style \(#{Regexp.escape(targets.first)}\)}i)
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

      before(:each) do
        pwd = Gem.win_platform? ? 'C:/path/to/module' : '/path/to/module'
        allow(Pathname).to receive(:pwd).and_return(Pathname.new(pwd))
      end

      it 'includes the path to the target relative to the PWD in the spinner text' do
        expect(spinner_text).to match(%r{checking metadata style \(metadata\.json\)}i)
      end
    end
  end

  it_behaves_like 'it accepts metadata.json targets'

  describe '.parse_options' do
    subject(:command_args) { described_class.parse_options(options, targets) }

    let(:options) { {} }
    let(:targets) { %w[target1 target2.json] }

    it 'sets the output format as JSON' do
      expect(command_args.join(' ')).to match(%r{--format json})
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
      described_class.parse_output(report, { stdout: metadata_json_lint_output }, targets)
    end

    let(:report) { PDK::Report.new }
    let(:metadata_json_lint_output) { { result: 'something', errors: errors, warnings: warnings }.to_json }
    let(:targets) { ['metadata.json'] }
    let(:errors) { [] }
    let(:warnings) { [] }

    context 'when passed multiple targets' do
      let(:targets) { ['metadata.json', 'another.json'] }

      it 'raises an ArgumentError' do
        expect { parse_output }.to raise_error(ArgumentError, a_string_matching(%r{more than 1 target provided}i))
      end
    end

    context 'when metadata-json-lint generates no output' do
      let(:metadata_json_lint_output) { '' }

      it 'adds a passing event for the target to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first,
          source:   described_class.name,
          state:    :passed,
          severity: :ok,
        )

        parse_output
      end
    end

    context 'when metadata-json-lint generates bad JSON' do
      let(:metadata_json_lint_output) { 'some unhandled error' }

      it 'adds an error event for the target to the report' do
        expect(report).to receive(:add_event).with(
          file:     targets.first,
          source:   described_class.name,
          state:    :error,
          severity: :error,
          message:  metadata_json_lint_output,
        )

        parse_output
      end
    end

    context 'when metadata-json-lint finds problems in the target' do
      let(:errors) { [{ 'msg' => 'some error', 'check' => 'error-check' }] }
      let(:warnings) { [{ 'msg' => 'some warning', 'check' => 'warning-check' }] }

      it 'adds a failure event to the report for each error' do
        allow(report).to receive(:add_event)

        errors.each do |error|
          expect(report).to receive(:add_event).with(
            file:     targets.first,
            source:   described_class.name,
            message:  error['msg'],
            test:     error['check'],
            severity: 'error',
            state:    :failure,
          )
        end

        parse_output
      end

      it 'adds a failure event to the report for each warning' do
        allow(report).to receive(:add_event)

        warnings.each do |warning|
          expect(report).to receive(:add_event).with(
            file:     targets.first,
            source:   described_class.name,
            message:  warning['msg'],
            test:     warning['check'],
            severity: 'warning',
            state:    :failure,
          )
        end

        parse_output
      end
    end
  end

  describe '.invoke' do
    let(:targets) { ['metadata.json', 'test.json'] }

    let(:expected_args) do
      if Gem.win_platform?
        %w[ruby -W0].concat([described_class.cmd_path, described_class.parse_options({}, [])])
      else
        [described_class.cmd_path, described_class.parse_options({}, [])]
      end
    end

    let(:command_double) do
      instance_double(PDK::CLI::Exec::Command,
                      :context=    => true,
                      :add_spinner => true,
                      :execute!    => { stdout: '', stderr: '', exit_code: 0 })
    end

    before(:each) do
      allow(PDK::Util::Bundler).to receive(:ensure_binstubs!).with(described_class.cmd)
      targets.each do |target|
        allow(File).to receive(:directory?).with(target).and_return(false)
      end
    end

    it 'invokes metadata-json-lint once per target' do
      targets.each do |target|
        cmd_args = expected_args.dup.flatten << target
        expect(PDK::CLI::Exec::Command).to receive(:new).with(*cmd_args).and_return(command_double)
      end

      described_class.invoke(PDK::Report.new, targets: targets)
    end
  end
end
