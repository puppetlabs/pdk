require 'spec_helper'
require 'pdk/validate/puppet/puppet_epp_validator'

describe PDK::Validate::Puppet::PuppetEPPValidator do
  subject(:validator) { described_class.new(validator_context, options) }

  let(:validator_context) { nil }
  let(:options) { {} }
  let(:tmpdir) { File.join('/', 'tmp', 'puppet-epp-validate') }

  before(:each) do
    allow(Dir).to receive(:mktmpdir).with('puppet-epp-validate').and_return(tmpdir)
    allow(PDK::Util::Filesystem).to receive(:remove_entry_secure).with(tmpdir)
  end

  it 'defines the base validator attributes' do
    expect(validator).to have_attributes(
      name: 'puppet-epp',
      cmd:  'puppet',
    )
    expect(validator.spinner_text_for_targets(nil)).to match(%r{puppet EPP syntax}i)
  end

  describe '.pattern' do
    it 'only contextually matches embedded puppet templates' do
      expect(validator).to receive(:contextual_pattern).with('**/*.epp') # rubocop:disable RSpec/SubjectStub This is fine
      validator.pattern
    end
  end

  describe '.invoke' do
    context 'when the validator runs correctly' do
      before(:each) do
        allow(validator).to receive(:parse_targets).and_return([[], [], []]) # rubocop:disable RSpec/SubjectStub
      end

      it 'cleans up the temp dir after invoking' do
        expect(validator).to receive(:remove_validate_tmpdir) # rubocop:disable RSpec/SubjectStub
        validator.invoke(PDK::Report.new)
      end
    end

    context 'when the validator raises an exception' do
      before(:each) do
        allow(validator).to receive(:parse_targets).and_raise(PDK::CLI::FatalError) # rubocop:disable RSpec/SubjectStub
      end

      it 'cleans up the temp dir after invoking' do
        expect(validator).to receive(:remove_validate_tmpdir) # rubocop:disable RSpec/SubjectStub
        expect {
          validator.invoke(PDK::Report.new)
        }.to raise_error(PDK::CLI::FatalError)
      end
    end
  end

  describe '.remove_validate_tmpdir' do
    after(:each) do
      validator.remove_validate_tmpdir
    end

    context 'when no temp dir has been created' do
      before(:each) do
        validator.instance_variable_set('@validate_tmpdir', nil)
      end

      it 'does not attempt to remove the directory' do
        expect(PDK::Util::Filesystem).not_to receive(:remove_entry_secure)
      end
    end

    context 'when a temp dir has been created' do
      before(:each) do
        validator.validate_tmpdir
      end

      context 'and the path is a directory' do
        before(:each) do
          allow(PDK::Util::Filesystem).to receive(:directory?).with(tmpdir).and_return(true)
        end

        it 'removes the directory' do
          expect(PDK::Util::Filesystem).to receive(:remove_entry_secure).with(tmpdir)
        end
      end

      context 'but the path is not a directory' do
        before(:each) do
          allow(PDK::Util::Filesystem).to receive(:directory?).with(tmpdir).and_return(false)
        end

        it 'does not attempt to remove the directory' do
          expect(PDK::Util::Filesystem).not_to receive(:remove_entry_secure)
        end
      end
    end
  end

  describe '.parse_options' do
    subject(:command_args) { validator.parse_options(targets) }

    let(:targets) { %w[target1 target2.epp] }

    before(:each) do
      allow(Gem).to receive(:win_platform?).and_return(false)
    end

    it 'invokes `puppet epp validate`' do
      expect(command_args.first(2)).to eq(%w[epp validate])
    end

    it 'appends the targets to the command arguments' do
      expect(command_args.last(targets.count)).to eq(targets)
    end

    context 'when auto-correct is enabled' do
      let(:options) { { auto_correct: true } }

      it 'has no effect' do
        expect(command_args).to eq(%w[epp validate --config /dev/null --modulepath].push(tmpdir).concat(targets))
      end
    end
  end

  describe '.parse_output' do
    subject(:parse_output) do
      validator.parse_output(report, { stderr: validate_output }, targets)
    end

    let(:report) { PDK::Report.new }
    let(:validate_output) do
      [
        mock_validate('fail.epp', 1, 2, 'test message 1', 'error'),
        mock_validate('fail.epp', 1, nil, 'test message 2', 'error'),
        mock_validate('fail.epp', nil, nil, 'test message 3', 'error'),
        mock_validate(nil, 1, nil, 'test message 4', 'error'),
        "error: 5.3.4 test-type-1 (file: warning.epp, line: 34, column: 45)\n",
        "error: 5.3.4 test-type-2 (file: warning.epp, line: 34)\n",
        "error: 5.3.4 test-type-3 (line: 34, column: 45)\n",
        "error: 5.3.4 test-type-4 (line: 34)\n",
        "error: 5.3.4 test-type-5 (file: warning.epp)\n",
        "error: language validaton logged 2 errors. giving up\n",
      ].join('')
    end

    let(:targets) { ['pass.epp', 'fail.epp'] }

    def mock_validate(file, line, column, message, severity)
      output = "#{severity}: #{message}"
      if file && line && column
        output << " at #{file}:#{line}:#{column}\n"
      elsif file && line
        output << " at #{file}:#{line}\n"
      elsif line
        output << " at line #{line}\n"
      elsif file
        output << " in #{file}\n"
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
          file:     'pass.epp',
          source:   validator.name,
          state:    :passed,
          severity: :ok,
        )
      end
    end

    context 'with Puppet <= 5.3.3' do
      it 'handles syntax error locations with a file, line, and column' do
        expect(report).to receive(:add_event).with(
          file:     'fail.epp',
          source:   validator.name,
          state:    :failure,
          message:  'test message 1',
          severity: 'error',
          column:   '2',
          line:     '1',
        )
      end

      it 'handles syntax error locations with a file and line' do
        expect(report).to receive(:add_event).with(
          file:     'fail.epp',
          source:   validator.name,
          state:    :failure,
          message:  'test message 2',
          severity: 'error',
          line:     '1',
        )
      end

      it 'handles syntax error locations with a file' do
        expect(report).to receive(:add_event).with(
          file:     'fail.epp',
          source:   validator.name,
          state:    :failure,
          message:  'test message 3',
          severity: 'error',
        )
      end

      it 'handles syntax error locations with a line' do
        expect(report).to receive(:add_event).with(
          source:   validator.name,
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
          file:     'warning.epp',
          source:   validator.name,
          state:    :failure,
          message:  '5.3.4 test-type-1',
          severity: 'error',
          column:   '45',
          line:     '34',
        )
      end

      it 'handles syntax error locations with a file and line' do
        expect(report).to receive(:add_event).with(
          file:     'warning.epp',
          source:   validator.name,
          state:    :failure,
          message:  '5.3.4 test-type-2',
          severity: 'error',
          line:     '34',
        )
      end

      it 'handles syntax error locations with a line and column' do
        expect(report).to receive(:add_event).with(
          source:   validator.name,
          state:    :failure,
          message:  '5.3.4 test-type-3',
          severity: 'error',
          column:   '45',
          line:     '34',
        )
      end

      it 'handles syntax error locations with a line' do
        expect(report).to receive(:add_event).with(
          source:   validator.name,
          state:    :failure,
          message:  '5.3.4 test-type-4',
          severity: 'error',
          line:     '34',
        )
      end

      it 'handles syntax error locations with a file' do
        expect(report).to receive(:add_event).with(
          file:     'warning.epp',
          source:   validator.name,
          state:    :failure,
          message:  '5.3.4 test-type-5',
          severity: 'error',
        )
      end
    end

    context 'Parser encounters a Ruby error' do
      let(:targets) { ['ruby_error.epp'] }
      let(:validate_output) do
        "C:/PWKit/Puppet/sys/ruby/lib/ruby/gems/2.4.0/gems/puppet-5.5.2-x64-mingw32/lib/puppet/environments.rb:38:in \`"\
        "get!': Could not find a directory environment named 'PUPPET_MASTER_SERVER=' anywhere in the path: "\
        "C:/ProgramData/PuppetLabs/code/environments. Does the directory exist? (Puppet::Environments::EnvironmentNotFound)\n"
      end

      it 'handles the Ruby error and prints it out as the message' do
        expect(report).to receive(:add_event).with(
          source:   validator.name,
          state:    :failure,
          message:  validate_output.split("\n").first,
        )
      end
    end
  end

  describe '.null_file' do
    subject { validator.null_file }

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
