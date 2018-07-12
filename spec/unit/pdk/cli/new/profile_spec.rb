require 'spec_helper'

describe 'PDK::CLI new profile' do
  let(:help_text) { a_string_matching(%r{^USAGE\s+pdk new profile}m) }

  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(%r{must be run from inside a valid module}))

      expect { PDK::CLI.run(%w[new profile test_profile]) }.to exit_nonzero
    end
  end

  context 'when run from inside a module' do
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return('/path/to/test/module')
    end

    context 'and not provided with a profile name' do
      it 'exits non-zero and prints the `pdk new profile` help' do
        expect { PDK::CLI.run(%w[new profile]) }.to exit_nonzero.and output(help_text).to_stdout
      end
    end

    context 'and provided an empty string as the profile name' do
      it 'exits non-zero and prints the `pdk new profile` help' do
        expect { PDK::CLI.run(['new', 'profile', '']) }.to exit_nonzero.and output(help_text).to_stdout
      end
    end

    context 'and provided an invalid profile name' do
      it 'exits with an error' do
        expect(logger).to receive(:error).with(a_string_matching(%r{'test-profile' is not a valid profile name}))

        expect { PDK::CLI.run(%w[new profile test-profile]) }.to exit_nonzero
      end
    end

    context 'and provided a valid profile name' do
      let(:generator) { instance_double('PDK::Generate::Profile') }

      it 'generates the profile' do
        expect(PDK::Generate::Profile).to receive(:new).with(anything, 'test_profile', instance_of(Hash)).and_return(generator)
        expect(generator).to receive(:run)

        PDK::CLI.run(%w[new profile test_profile])
      end

      context 'and a custom template URL' do
        it 'generates the profile from the custom template' do
          expect(PDK::Generate::Profile).to receive(:new)
            .with(anything, 'test_profile', :'template-url' => 'https://custom/template')
            .and_return(generator)
          expect(generator).to receive(:run)

          PDK::CLI.run(%w[new profile test_profile --template-url https://custom/template])
        end
      end
    end
  end
end
