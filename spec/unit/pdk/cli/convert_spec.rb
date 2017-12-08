require 'spec_helper'

describe 'PDK::CLI convert' do
  let(:help_text) { a_string_matching(%r{^USAGE\s+pdk convert}m) }

  context 'when not run from inside a module' do
    include_context 'run outside module'

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
      it 'invokes the converter with the default template' do
        expect(PDK::Module::Convert).to receive(:invoke).with(:'template-url' => PDK::Util.default_template_url)

        PDK::CLI.run(['convert'])
      end
    end

    context 'and the --template-url option has been passed' do
      it 'invokes the converter with the user supplied template' do
        expect(PDK::Module::Convert).to receive(:invoke).with(:'template-url' => 'https://my/template')

        PDK::CLI.run(['convert', '--template-url', 'https://my/template'])
      end
    end

    context 'and the --noop flag has been passed' do
      it 'passes the noop option through to the converter' do
        expect(PDK::Module::Convert).to receive(:invoke).with(:noop => true, :'template-url' => anything)

        PDK::CLI.run(['convert', '--noop'])
      end
    end

    context 'and the --force flag has been passed' do
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
