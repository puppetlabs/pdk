require 'spec_helper'

describe 'PDK::CLI convert' do
  let(:help_text) { a_string_matching(%r{^USAGE\s+pdk convert}m) }
  let(:backup_warning) { a_string_matching(%r{backup before continuing}i) }

  context 'when not run from inside a module' do
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return(nil)
    end

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(%r{must be run from inside a valid module}))

      expect {
        PDK::CLI.run(%w[convert])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).not_to eq(0)
      }
    end
  end

  context 'when run from inside a module' do
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/test/module')
    end

    context 'and provided no flags' do
      before(:each) do
        allow(logger).to receive(:info).with(backup_warning)
        allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(a_string_matching(%r{Do you want to proceed with conversion?}i)).and_return(true)
      end

      it 'asks the user if they want to continue' do
        expect(logger).to receive(:info).with(backup_warning)
        expect(PDK::CLI::Util).to receive(:prompt_for_yes).with(a_string_matching(%r{Do you want to proceed with conversion?}i)).and_return(true)
        allow(PDK::Module::Convert).to receive(:invoke).with(any_args).and_return(0)

        PDK::CLI.run(%w[convert])
      end

      it 'exits cleanly if the user chooses not to continue' do
        allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(a_string_matching(%r{Do you want to proceed with conversion?}i)).and_return(false)
        expect(PDK::Module::Convert).not_to receive(:invoke)

        expect {
          PDK::CLI.run(['convert'])
        }.to raise_error(SystemExit) { |error|
          expect(error.status).to eq(0)
        }
      end

      it 'invokes the converter with the default template if the user chooses to continue' do
        expect(PDK::Module::Convert).to receive(:invoke).with(:'template-url' => PDK::Generate::Module.default_template_url)

        PDK::CLI.run(['convert'])
      end
    end

    context 'and the --template-url option has been passed' do
      before(:each) do
        allow(logger).to receive(:info).with(backup_warning)
        allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(a_string_matching(%r{Do you want to proceed with conversion?}i)).and_return(true)
      end

      it 'invokes the converter with the user supplied template' do
        expect(PDK::Module::Convert).to receive(:invoke).with(:'template-url' => 'https://my/template')

        PDK::CLI.run(['convert', '--template-url', 'https://my/template'])
      end
    end

    context 'and the --noop flag has been passed' do
      it 'does not prompt the user before invoking the converter' do
        expect(logger).not_to receive(:info).with(backup_warning)
        expect(PDK::CLI::Util).not_to receive(:prompt_for_yes)
        allow(PDK::Module::Convert).to receive(:invoke).with(any_args)

        PDK::CLI.run(['convert', '--noop'])
      end

      it 'passes the noop option through to the converter' do
        expect(PDK::Module::Convert).to receive(:invoke).with(:noop => true, :'template-url' => anything)

        PDK::CLI.run(['convert', '--noop'])
      end
    end

    context 'and the --force flag has been passed' do
      it 'does not prompt the user before invoking the converter' do
        expect(logger).not_to receive(:info).with(backup_warning)
        expect(PDK::CLI::Util).not_to receive(:prompt_for_yes)
        allow(PDK::Module::Convert).to receive(:invoke).with(any_args)

        PDK::CLI.run(['convert', '--force'])
      end

      it 'passes the force option through to the converter' do
        expect(PDK::Module::Convert).to receive(:invoke).with(:force => true, :'template-url' => anything)

        PDK::CLI.run(['convert', '--force'])
      end
    end

    context 'and the --force and --noop flags have been passed' do
      it 'exits with an error' do
        expect(logger).to receive(:error).with(a_string_matching(%r{can not specify --noop and --force}i))

        expect {
          PDK::CLI.run(['convert', '--noop', '--force'])
        }.to raise_error(SystemExit) { |error|
          expect(error.status).not_to eq(0)
        }
      end
    end
  end
end
