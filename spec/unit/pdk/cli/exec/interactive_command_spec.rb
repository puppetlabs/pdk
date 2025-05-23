require 'spec_helper'
require 'pdk/cli/exec/interactive_command'

describe PDK::CLI::Exec::InteractiveCommand do
  subject(:command) { described_class.new('/bin/echo', 'foo') }

  before do
    allow(PDK::CLI::Util).to receive(:ci_environment?).and_return(false)
  end

  describe '.context=' do
    context 'when setting to an expected value' do
      it 'accepts :system' do
        expect { command.context = :system }.not_to raise_error
        expect(command.context).to eq :system
      end

      it 'accepts :module' do
        expect { command.context = :module }.not_to raise_error
        expect(command.context).to eq :module
      end

      it 'rejects other values' do
        expect { command.context = :foo }.to raise_error ArgumentError
      end
    end
  end

  describe '.add_spinner' do
    it 'raises an exception' do
      expect { command.add_spinner('test') }.to raise_error(/method.*not implemented/i)
    end
  end

  describe '.register_spinner' do
    let(:spinner) { instance_double(TTY::Spinner) }

    it 'raises an exception' do
      expect { command.register_spinner(spinner) }.to raise_error(/method.*not implemented/i)
    end
  end

  describe '.timeout=' do
    it 'raises an exception' do
      expect { command.timeout = 10 }.to raise_error(/method.*not implemented/i)
    end
  end

  describe '.timeout' do
    it 'raises an exception' do
      expect { command.timeout }.to raise_error(/method.*not implemented/i)
    end
  end

  describe '.exec_group=' do
    let(:exec_group) { instance_double(Object) }

    it 'raises an exception' do
      expect { command.exec_group = exec_group }.to raise_error(/method.*not implemented/i)
    end
  end

  describe '.execute!' do
    let(:environment) { {} }

    let(:exitstatus) { 0 }
    let(:child_status) { instance_double(Process::Status, exitstatus:) }

    before do
      # rubocop:disable RSpec/SubjectStub
      allow(command).to receive_messages(resolved_env_for_command: environment, child_status:)
      allow(command).to receive(:system) # Kernel is a mixed-in module
      # rubocop:enable RSpec/SubjectStub
    end

    context 'when running in the :system context' do
      before do
        command.context = :system
      end

      it "executes in parent process' bundler env" do
        expect(Bundler).not_to receive(:with_unbundled_env)

        command.execute!
      end

      it "returns child process' exit status" do
        result = command.execute!

        expect(result[:exit_code]).to eq(exitstatus)
      end

      context 'when child process exits non-zero' do
        let(:exitstatus) { 1 }

        it "returns child process' exit status" do
          result = command.execute!

          expect(result[:exit_code]).to eq(exitstatus)
        end
      end
    end

    context 'when running in the :module context' do
      before do
        command.context = :module
        allow(PDK::Util).to receive(:module_root).and_return(EMPTY_MODULE_ROOT)
      end

      it 'changes into the modroot path and then returns to original pwd' do
        allow(PDK::Util).to receive(:module_root).with(no_args).and_return('/modroot_path')
        allow(Dir).to receive(:pwd).and_return('/current_path')

        expect(Dir).to receive(:chdir).with('/modroot_path').ordered
        expect(Dir).to receive(:chdir).with('/current_path').ordered

        command.execute!
      end

      it "executes in module's bundler env" do
        expect(command).to receive(:run_process_in_clean_env!).and_call_original # rubocop:disable RSpec/SubjectStub This is fine

        command.execute!
      end

      it "returns child process' exit status" do
        result = command.execute!

        expect(result[:exit_code]).to eq(exitstatus)
      end

      context 'when child process exits non-zero' do
        let(:exitstatus) { 1 }

        it "returns child process' exit status" do
          result = command.execute!

          expect(result[:exit_code]).to eq(exitstatus)
        end
      end
    end

    context 'when running in the :pwd context' do
      before do
        command.context = :pwd
        allow(PDK::Util).to receive(:module_root).and_return(EMPTY_MODULE_ROOT)
      end

      it 'does not change out of pwd' do
        allow(PDK::Util).to receive(:module_root).with(no_args).and_return('/modroot_path')

        expect(Dir).not_to receive(:chdir)

        command.execute!
      end

      it "executes in module's bundler env" do
        expect(command).to receive(:run_process_in_clean_env!).and_call_original # rubocop:disable RSpec/SubjectStub This is fine

        command.execute!
      end

      it "returns child process' exit status" do
        result = command.execute!

        expect(result[:exit_code]).to eq(exitstatus)
      end

      context 'when child process exits non-zero' do
        let(:exitstatus) { 1 }

        it "returns child process' exit status" do
          result = command.execute!

          expect(result[:exit_code]).to eq(exitstatus)
        end
      end
    end
  end
end
