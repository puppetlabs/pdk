require 'spec_helper'

describe 'PDK::CLI new class' do
  let(:help_text) { a_string_matching(%r{^USAGE\s+pdk new class}m) }

  context 'when not run from inside a module' do
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return(nil)
    end

    it 'exits with a fatal error' do
      expect(logger).to receive(:fatal).with(a_string_matching(%r{must be run from inside a valid module}))

      expect {
        PDK::CLI.run(%w[new class test_class])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).not_to eq(0)
      }
    end
  end

  context 'when run from inside a module' do
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/test/module')
    end

    context 'and not provided with a class name' do
      it 'exits non-zero and prints the `pdk new class` help' do
        expect {
          PDK::CLI.run(%w[new class])
        }.to raise_error(SystemExit) { |error|
          expect(error.status).not_to eq(0)
        }.and output(help_text).to_stdout
      end
    end

    context 'and provided an empty string as the class name' do
      it 'exits non-zero and prints the `pdk new class` help' do
        expect {
          PDK::CLI.run(['new', 'class', ''])
        }.to raise_error(SystemExit) { |error|
          expect(error.status).not_to eq(0)
        }.and output(help_text).to_stdout
      end
    end

    context 'and provided an invalid class name' do
      it 'exits with a fatal error' do
        expect(logger).to receive(:fatal).with(a_string_matching(%r{'test-class' is not a valid class name}))

        expect {
          PDK::CLI.run(%w[new class test-class])
        }.to raise_error(SystemExit) { |error|
          expect(error.status).not_to eq(0)
        }
      end
    end

    context 'and provided a valid class name' do
      let(:generator) { instance_double('PDK::Generate::PuppetClass') }

      it 'generates the class' do
        expect(PDK::Generate::PuppetClass).to receive(:new).with(anything, 'test_class', instance_of(Hash)).and_return(generator)
        expect(generator).to receive(:run)

        PDK::CLI.run(%w[new class test_class])
      end

      context 'and a custom template URL' do
        it 'generates the class from the custom template' do
          expect(PDK::Generate::PuppetClass).to receive(:new)
            .with(anything, 'test_class', :'template-url' => 'https://custom/template')
            .and_return(generator)
          expect(generator).to receive(:run)

          PDK::CLI.run(%w[new class test_class --template-url https://custom/template])
        end
      end
    end
  end
end
