# frozen_string_literal: true

require 'spec_helper'

describe 'PDK::CLI update' do
  let(:help_text) { a_string_matching(%r{^USAGE\s+pdk update}m) }
  let(:updater) do
    instance_double(PDK::Module::Update, run: true, current_version: current_version, new_version: new_version)
  end
  let(:current_version) { '1.2.3' }
  let(:new_version) { '1.2.4' }

  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(%r{must be run from inside a valid module}))

      expect { PDK::CLI.run(%w[update]) }.to exit_nonzero
    end
  end

  context 'when run from inside a module' do
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/test/module')
      allow(PDK::Util).to receive(:module_pdk_compatible?).and_return(true)
    end

    context 'and provided no flags' do
      it 'invokes the updater with no options' do
        expect(PDK::Module::Update).to receive(:new).with({}).and_return(updater)
        expect(updater).to receive(:run)

        PDK::CLI.run(%w[update])
      end
    end

    context 'and the --noop flag has been passed' do
      it 'passes the noop option through to the updater' do
        expect(PDK::Module::Update).to receive(:new).with(noop: true).and_return(updater)
        expect(updater).to receive(:run)

        PDK::CLI.run(%w[update --noop])
      end
    end

    context 'and the --force flag has been passed' do
      it 'passes the force option through to the updater' do
        expect(PDK::Module::Update).to receive(:new).with(force: true).and_return(updater)
        expect(updater).to receive(:run)

        PDK::CLI.run(%w[update --force])
      end
    end

    context 'and the --force and --noop flags have been passed' do
      it 'exits with an error' do
        expect(logger).to receive(:error).with(a_string_matching(%r{can not specify --noop and --force}i))

        expect { PDK::CLI.run(%w[update --noop --force]) }.to exit_nonzero
      end
    end
  end

  context 'when run from inside an unconverted module' do
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/test/module')
      allow(PDK::Util).to receive(:module_pdk_compatible?).and_return(false)
    end

    context 'and provided no flags' do
      it 'raises ExitWithError' do
        expect(logger).to receive(:error).with(a_string_matching(%r{This module does not appear to be PDK compatible}i))

        expect { PDK::CLI.run(%w[update]) }.to exit_nonzero
      end
    end
  end
end
