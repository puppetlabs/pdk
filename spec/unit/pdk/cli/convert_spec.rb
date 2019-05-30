require 'spec_helper'

describe 'PDK::CLI convert' do
  let(:help_text) { a_string_matching(%r{^USAGE\s+pdk convert}m) }

  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(%r{must be run from inside a valid module}))

      expect { PDK::CLI.run(%w[convert]) }.to exit_nonzero
    end
  end

  context 'when run from inside a module' do
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/test/module')
    end

    context 'and provided no flags' do
      it 'invokes the converter with no template specified' do
        expect(PDK::Module::Convert).to receive(:invoke).with(hash_not_including(:'template-url'))

        PDK::CLI.run(['convert'])
      end
    end

    context 'and the --template-url option has been passed' do
      it 'invokes the converter with the user supplied template' do
        expect(PDK::Module::Convert).to receive(:invoke).with(hash_including(:'template-url' => 'https://my/template'))

        PDK::CLI.run(['convert', '--template-url', 'https://my/template'])
      end
    end

    context 'and the --template-ref option has been passed' do
      it 'invokes the converter with the user supplied template' do
        expect(PDK::Module::Convert).to receive(:invoke).with(hash_including(:'template-url' => 'https://my/template', :'template-ref' => '1.0.0'))

        PDK::CLI.run(['convert', '--template-url', 'https://my/template', '--template-ref', '1.0.0'])
      end
    end

    context 'and the --noop flag has been passed' do
      it 'passes the noop option through to the converter' do
        expect(PDK::Module::Convert).to receive(:invoke).with(hash_including(noop: true))

        PDK::CLI.run(['convert', '--noop'])
      end
    end

    context 'and the --force flag has been passed' do
      it 'passes the force option through to the converter' do
        expect(PDK::Module::Convert).to receive(:invoke).with(hash_including(force: true))

        PDK::CLI.run(['convert', '--force'])
      end
    end

    context 'and the --force and --noop flags have been passed' do
      it 'exits with an error' do
        expect(logger).to receive(:error).with(a_string_matching(%r{can not specify --noop and --force}i))

        expect { PDK::CLI.run(['convert', '--noop', '--force']) }.to exit_nonzero
      end
    end

    context 'and the --skip-interview flag has been passed' do
      it 'passes the skip-interview option through to the converter' do
        expect(PDK::Module::Convert).to receive(:invoke).with(hash_including(:'skip-interview' => true))

        PDK::CLI.run(['convert', '--skip-interview'])
      end
    end

    context 'and the --full-interview flag has been passed' do
      it 'passes the full-interview option through to the converter' do
        expect(PDK::Module::Convert).to receive(:invoke).with(hash_including(:'full-interview' => true))

        PDK::CLI.run(['convert', '--full-interview'])
      end
    end

    context 'and the --skip-interview and --full-interview flags have been passed' do
      it 'ignores full-interview and continues with a log message' do
        expect(logger).to receive(:info).with(a_string_matching(%r{Ignoring --full-interview and continuing with --skip-interview.}i))
        expect(PDK::Module::Convert).to receive(:invoke).with(hash_including(:'skip-interview' => true, :'full-interview' => false))

        PDK::CLI.run(['convert', '--skip-interview', '--full-interview'])
      end
    end

    context 'and the --force and --full-interview flags have been passed' do
      it 'ignores full-interview and continues with a log message' do
        expect(logger).to receive(:info).with(a_string_matching(%r{Ignoring --full-interview and continuing with --force.}i))
        expect(PDK::Module::Convert).to receive(:invoke).with(hash_including(:force => true, :'full-interview' => false))

        PDK::CLI.run(['convert', '--force', '--full-interview'])
      end
    end
  end
end
