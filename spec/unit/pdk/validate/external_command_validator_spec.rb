require 'spec_helper'
require 'pdk/validate/external_command_validator'

describe PDK::Validate::ExternalCommandValidator do
  let(:validator) { described_class.new(validator_context, validator_options) }
  let(:validator_context) { PDK::Context::Module.new(EMPTY_MODULE_ROOT, EMPTY_MODULE_ROOT) }
  let(:validator_options) { {} }
  let(:targets) { [] }
  let(:skipped_targets) { [] }
  let(:invalid_targets) { [] }
  let(:parsed_targets) { [targets, skipped_targets, invalid_targets] }
  let(:report) { PDK::Report.new }

  before(:each) do
    allow(validator).to receive(:name).and_return('mock_name')
    allow(validator).to receive(:parse_targets).and_return(parsed_targets)
  end

  describe '.spinner' do
    it 'returns nil' do
      expect(validator.spinner).to be_nil
    end
  end

  describe '.spinner_text_for_targets' do
    it 'returns nil' do
      expect(validator.spinner_text_for_targets(%w[123 abc])).to be_nil
    end
  end

  describe '.cmd' do
    it 'returns nil' do
      expect(validator.cmd).to be_nil
    end
  end

  describe '.cmd_path' do
    before(:each) do
      allow(validator).to receive(:cmd).and_return('command')
    end

    it 'returns a String' do
      expect(validator.cmd_path).to be_a(String)
    end
  end

  describe '.parse_options' do
    it 'returns empty array' do
      expect(validator.parse_options([])).to eq([])
    end
  end

  describe '.parse_output' do
    it 'returns nil' do
      expect(validator.parse_output(report, nil, [])).to be_nil
    end
  end

  describe '.prepare_invoke!' do
    before(:each) do
      allow(validator).to receive(:cmd).and_return('mock_cmd')
    end

    it 'calls parse_targets only once' do
      expect(validator).to receive(:parse_targets).once.and_return(parsed_targets)

      validator.prepare_invoke!
      validator.prepare_invoke!
      validator.prepare_invoke!
    end

    context 'when spinners are disabled' do
      let(:targets) { ['target'] }

      before(:each) do
        allow(validator).to receive(:spinners_enabled?).and_return(false)
      end

      it 'does not create spinners for the commands' do
        validator.prepare_invoke!

        expect(validator.commands.count).to eq(1)
        expect(validator.commands[0][:command].spinner).to be_nil
      end
    end

    context 'when spinners are enabled' do
      let(:targets) { ['target'] }

      let(:dummy_command) do
        instance_double(PDK::CLI::Exec::Command, :context= => nil, :execute! => { exit_code: 0 })
      end

      before(:each) do
        allow(validator).to receive(:spinners_enabled?).and_return(true)
        expect(PDK::CLI::Exec::Command).to receive(:new).and_return(dummy_command)
      end

      it 'adds a spinner for a standalone command' do
        expect(dummy_command).to receive(:add_spinner).and_return(nil)
        validator.prepare_invoke!

        expect(validator.commands.count).to eq(1)
      end

      context 'given a parent validator with a multi spinner' do
        let(:parent_validator) do
          require 'pdk/cli/util/spinner'
          instance_double(PDK::Validate::Validator, spinner: TTY::Spinner::Multi.new('test'))
        end
        let(:validator_options) { { parent_validator: parent_validator } }

        it 'registers a spinner for a hierarchical command' do
          expect(dummy_command).to receive(:register_spinner).and_return(nil)
          validator.prepare_invoke!

          expect(validator.commands.count).to eq(1)
        end
      end
    end

    context 'when there are no valid targets' do
      let(:targets) { [] }

      context 'when empty targets are not allowed' do
        before(:each) do
          allow(validator).to receive(:allow_empty_targets?).and_return(false)
        end

        it 'executes no commands' do
          validator.prepare_invoke!
          expect(validator.commands).to be_empty
        end
      end

      context 'when empty targets are allowed' do
        before(:each) do
          allow(validator).to receive(:allow_empty_targets?).and_return(true)
        end

        it 'executes a single command with no targets' do
          validator.prepare_invoke!
          expect(validator.commands.count).to eq(1)
          expect(validator.commands[0][:invokation_targets]).to eq([])
        end
      end
    end

    context 'when invoke_style is :once' do
      before(:each) do
        allow(validator).to receive(:invoke_style).and_return(:once)
      end

      context 'when validating less than 1000 targets' do
        let(:targets) { (1..999).map(&:to_s) }

        it 'executes a single command' do
          validator.prepare_invoke!
          expect(validator.commands.count).to eq(1)
        end
      end

      context 'when validating more than 1000 targets' do
        let(:targets) { (1..3000).map(&:to_s) }

        it 'executes a single command for each block of 1000 targets' do
          validator.prepare_invoke!
          expect(validator.commands.count).to eq(3)
        end
      end
    end

    context 'when invoke_style is :per_target' do
      before(:each) do
        allow(validator).to receive(:invoke_style).and_return(:per_target)
      end

      context 'when validating less than 1000 targets' do
        let(:targets) { (1..100).map(&:to_s) }

        it 'executes a single command per target' do
          validator.prepare_invoke!
          expect(validator.commands.count).to eq(100)
        end
      end
    end
  end

  describe '.invoke' do
    subject(:invoke) { validator.invoke(report) }

    let(:skipped_targets) { ['skipped'] }
    let(:invalid_targets) { ['invalid'] }

    before(:each) do
      allow(validator).to receive(:cmd).and_return('command')
    end

    context 'when no targets to validate' do
      it 'calls prepare_invoke!' do
        expect(validator).to receive(:prepare_invoke!).and_call_original
        invoke
      end

      it 'calls process_skipped!' do
        expect(validator).to receive(:process_skipped).with(report, skipped_targets).and_call_original
        invoke
      end

      it 'calls process_invalid!' do
        expect(validator).to receive(:process_invalid).with(report, invalid_targets).and_call_original
        invoke
      end

      it 'does not call any validation helper methods' do
        expect(PDK::Util::Bundler).not_to receive(:ensure_binstubs!)
        expect(PDK::CLI::ExecGroup).not_to receive(:create)

        invoke
      end
    end

    context 'with at least one target to validate' do
      let(:success_command) do
        instance_double(PDK::CLI::Exec::Command, :context= => nil, :execute! => { exit_code: 0 })
      end

      let(:fail_command1) do
        instance_double(PDK::CLI::Exec::Command, :context= => nil, :execute! => { exit_code: 1 })
      end

      let(:fail_command2) do
        instance_double(PDK::CLI::Exec::Command, :context= => nil, :execute! => { exit_code: 2 })
      end

      before(:each) do
        # Disable the spinners
        allow(validator).to receive(:spinners_enabled?).and_return(false)
        allow(PDK::Util::Bundler).to receive(:ensure_binstubs!).and_return(nil)
        # Force a command per target to test the execution grouping
        allow(validator).to receive(:invoke_style).and_return(:per_target)
        allow(PDK::CLI::Exec::Command).to receive(:new).and_return(success_command, fail_command2, fail_command1)
      end

      context 'when parse_output fails' do
        let(:targets) { ['test'] }

        before(:each) do
          expect(validator).to receive(:parse_output).with(report, Hash, ['test']).and_raise(PDK::Validate::ParseOutputError, 'test_error')
        end

        it 'prints the validator output to STDERR' do
          expect($stderr).to receive(:puts).with('test_error')
          invoke
        end
      end

      context 'with only successful validations' do
        let(:targets) { ['success'] }

        it 'calls PDK::Util::Bundler.ensure_binstubs!' do
          expect(PDK::Util::Bundler).to receive(:ensure_binstubs!).and_return(nil)
          invoke
        end

        it 'calls parse_output for each command' do
          expect(validator).to receive(:parse_output).with(report, Hash, ['success'])
          invoke
        end

        it 'returns zero' do
          expect(invoke).to eq(0)
        end
      end

      context 'with successful and failed validations' do
        let(:targets) { %w[success fail2 fail1] }

        it 'calls PDK::Util::Bundler.ensure_binstubs!' do
          expect(PDK::Util::Bundler).to receive(:ensure_binstubs!).and_return(nil)
          invoke
        end

        it 'calls parse_output for each command' do
          expect(validator).to receive(:parse_output).with(report, Hash, ['success'])
          expect(validator).to receive(:parse_output).with(report, Hash, ['fail1'])
          expect(validator).to receive(:parse_output).with(report, Hash, ['fail2'])
          invoke
        end

        it 'returns highest exit code' do
          expect(invoke).to eq(2)
        end
      end
    end
  end
  # invoke
end
