require 'spec_helper'

describe 'PDK::CLI new role' do
  let(:help_text) { a_string_matching(%r{^USAGE\s+pdk new role}m) }

  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(%r{must be run from inside a valid module}))

      expect { PDK::CLI.run(%w[new role test_role]) }.to exit_nonzero
    end
  end

  context 'when run from inside a module' do
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/test/module')
    end

    context 'and not provided with a role name' do
      it 'exits non-zero and prints the `pdk new role` help' do
        expect { PDK::CLI.run(%w[new role]) }.to exit_nonzero.and output(help_text).to_stdout
      end
    end

    context 'and provided an empty string as the role name' do
      it 'exits non-zero and prints the `pdk new role` help' do
        expect { PDK::CLI.run(['new', 'role', '']) }.to exit_nonzero.and output(help_text).to_stdout
      end
    end

    context 'and provided an invalid role name' do
      it 'exits with an error' do
        expect(logger).to receive(:error).with(a_string_matching(%r{'test-role' is not a valid role name}))

        expect { PDK::CLI.run(%w[new role test-role]) }.to exit_nonzero
      end
    end

    context 'and provided a valid role name' do
      let(:generator) { instance_double('PDK::Generate::Role') }

      it 'generates the role' do
        expect(PDK::Generate::Role).to receive(:new).with(anything, 'test_role', instance_of(Hash)).and_return(generator)
        expect(generator).to receive(:run)

        PDK::CLI.run(%w[new role test_role])
      end

      context 'and a custom template URL' do
        it 'generates the role from the custom template' do
          expect(PDK::Generate::Role).to receive(:new)
            .with(anything, 'test_role', :'template-url' => 'https://custom/template')
            .and_return(generator)
          expect(generator).to receive(:run)

          PDK::CLI.run(%w[new role test_role --template-url https://custom/template])
        end
      end
    end
  end
end
