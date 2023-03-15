require 'spec_helper'
require 'pdk/cli'

describe 'PDK::CLI new class' do
  let(:help_text) { a_string_matching(%r{^USAGE\s+pdk new class}m) }

  before(:each) do
    # Stop printing out the result
    allow(PDK::CLI::Util::UpdateManagerPrinter).to receive(:print_summary)
  end

  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(%r{must be run from inside a valid module}))

      expect { PDK::CLI.run(%w[new class test_class]) }.to exit_nonzero
    end

    it 'does not submit the command to analytics' do
      expect(analytics).not_to receive(:screen_view)

      expect { PDK::CLI.run(%w[new class test_class]) }.to exit_nonzero
    end
  end

  context 'when run from inside a module' do
    let(:root_dir) { '/path/to/test/module' }

    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return(root_dir)
    end

    context 'and not provided with a class name' do
      it 'exits non-zero and prints the `pdk new class` help' do
        expect { PDK::CLI.run(%w[new class]) }.to exit_nonzero.and output(help_text).to_stdout
      end

      it 'does not submit the command to analytics' do
        expect(analytics).not_to receive(:screen_view)

        expect { PDK::CLI.run(%w[new class]) }.to exit_nonzero.and output(help_text).to_stdout
      end
    end

    context 'and provided an empty string as the class name' do
      it 'exits non-zero and prints the `pdk new class` help' do
        expect { PDK::CLI.run(['new', 'class', '']) }.to exit_nonzero.and output(help_text).to_stdout
      end

      it 'does not submit the command to analytics' do
        expect(analytics).not_to receive(:screen_view)

        expect { PDK::CLI.run(['new', 'class', '']) }.to exit_nonzero.and output(help_text).to_stdout
      end
    end

    context 'and provided an invalid class name' do
      it 'exits with an error' do
        expect(logger).to receive(:error).with(a_string_matching(%r{'test-class' is not a valid class name}))

        expect { PDK::CLI.run(%w[new class test-class]) }.to exit_nonzero
      end

      it 'does not submit the command to analytics' do
        expect(analytics).not_to receive(:screen_view)

        expect { PDK::CLI.run(%w[new class test-class]) }.to exit_nonzero
      end
    end

    context 'and provided a valid class name' do
      let(:generator) { instance_double('PDK::Generate::PuppetClass', run: true) }

      after(:each) do
        PDK::CLI.run(%w[new class test_class])
      end

      it 'generates the class' do
        expect(PDK::Generate::PuppetClass).to receive(:new).with(anything, 'test_class', instance_of(Hash)).and_return(generator)
        expect(generator).to receive(:run)
      end

      it 'submits the command to analytics' do
        allow(PDK::Generate::PuppetClass).to receive(:new).and_return(generator)

        expect(analytics).to receive(:screen_view).with(
          'new_class',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end
  end
end
