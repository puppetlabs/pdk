require 'spec_helper'

describe PDK::CLI::Exec::Command do
  subject(:command) { described_class.new('/bin/echo', 'foo') }

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
    context 'without --debug' do
      before(:each) do
        allow(logger).to receive(:debug?).and_return(false)
        command.add_spinner('message')
      end
      it { expect(command.instance_variable_get(:@spinner)).to be_a TTY::Spinner }
    end
    context 'with --debug' do
      before(:each) do
        allow(logger).to receive(:debug?).and_return(true)
        command.add_spinner('message')
      end
      it { expect(command.instance_variable_get(:@spinner)).to be_nil }
    end
  end

  describe '.register_spinner' do
    let(:spinner) { instance_double('spinner') }

    context 'without --debug' do
      before(:each) do
        allow(logger).to receive(:debug?).and_return(false)
        command.register_spinner(spinner)
      end
      it { expect(command.instance_variable_get(:@spinner)).to eq spinner }
    end
    context 'with --debug' do
      before(:each) do
        allow(logger).to receive(:debug?).and_return(true)
        command.register_spinner(spinner)
      end
      it { expect(command.instance_variable_get(:@spinner)).to be_nil }
    end
  end

  describe '.execute!' do
    let(:process) { instance_double('ChildProcess.build(*@argv)') }
    let(:io) { instance_double('ChildProcess.io') }

    before(:each) do
      expect(ChildProcess).to receive(:build).with('/bin/echo', 'foo').and_return(process)
      allow(process).to receive(:leader=)
      allow(io).to receive(:stdout=)
      allow(io).to receive(:stderr=)
      allow(process).to receive(:io).and_return(io)
      allow(process).to receive(:wait)
    end

    context 'when running in the :system context' do
      before(:each) do
        command.context = :system
        expect(process).to receive(:start).with(no_args)
        allow(process).to receive(:exit_code).and_return 0
      end

      it { expect { command.execute! }.not_to raise_error }
    end

    context 'when running in the :module context' do
      let(:environment) { {} }

      before(:each) do
        command.context = :module
        expect(process).to receive(:start).with(no_args)
        allow(PDK::Util).to receive(:module_root).with(no_args).and_return('/invalid_path')
        allow(Dir).to receive(:chdir).with('/invalid_path').and_yield
        allow(process).to receive(:exit_code).and_return 0
        allow(process).to receive(:environment).and_return environment
      end

      it { expect { command.execute! }.not_to raise_error }
    end
  end
end
