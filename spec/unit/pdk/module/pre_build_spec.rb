require 'spec_helper'
require 'pdk/module/pre_build'

describe PDK::Module::PreBuild do
  # Note that this test setup is quite fragile and indicates that the method
  # under test really needs to be refactored

  describe '#run_validations' do
    let(:report) { instance_double(PDK::Report, write_text: nil) }

    before do
      allow(PDK::CLI::Util).to receive(:validate_puppet_version_opts).and_return(nil)
      allow(PDK::CLI::Util).to receive(:module_version_check).and_return(nil)
      allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env).and_return(gemset: {}, ruby_version: '1.2.3')
      allow(PDK::Util::PuppetVersion).to receive(:fetch_puppet_dev).and_return(nil)
      allow(PDK::Util::RubyVersion).to receive(:use).and_return(nil)
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!).and_return(nil)
    end

    it 'calls the validators' do
      expect(PDK::Validate).to receive(:invoke_validators_by_name).and_return([0, report])
      described_class.run_validations({})
    end

    it 'raises when the validator returns a non-zero exit code' do
      expect(PDK::Validate).to receive(:invoke_validators_by_name).and_return([1, report])
      expect { described_class.run_validations({}) }.to raise_error(PDK::CLI::ExitWithError)
    end
  end

  describe '#run_documentation' do
    let(:command) { double(PDK::CLI::Exec::InteractiveCommand, :context= => nil) } # rubocop:disable RSpec/VerifiedDoubles
    let(:command_stdout) { 'Success' }
    let(:command_exit_code) { 0 }

    before do
      expect(PDK::CLI::Exec::InteractiveCommand).to receive(:new).and_return(command)
      expect(command).to receive(:execute!).and_return(stdout: command_stdout, exit_code: command_exit_code)
    end

    it 'executes a command in the context of the module' do
      expect(command).to receive(:context=).with(:module)
      described_class.run_documentation
    end

    context 'when the command returns a non-zero exit code' do
      let(:command_stdout) { 'Fail' }
      let(:command_exit_code) { 1 }

      it 'raises' do
        expect { described_class.run_documentation }.to raise_error(PDK::CLI::ExitWithError)
      end
    end
  end
end
