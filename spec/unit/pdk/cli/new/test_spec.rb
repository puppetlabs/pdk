require 'spec_helper'
require 'pdk/cli'

describe 'PDK::CLI new test' do
  let(:help_text) { a_string_matching(/^USAGE\s+pdk new test/m) }

  before do
    # Stop printing out the result
    allow(PDK::CLI::Util::UpdateManagerPrinter).to receive(:print_summary)
  end

  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(/must be run from inside a valid module/))

      expect { PDK::CLI.run(['new', 'test', 'my_object']) }.to exit_nonzero
    end
  end

  context 'when run from inside a module' do
    let(:root_dir) { '/path/to/test/module' }

    before do
      allow(PDK::Util).to receive(:module_root).and_return(root_dir)
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!)
      allow(PDK::Util::RubyVersion).to receive(:use)
      allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env).and_return(ruby_version: '2.4.5', gemset: { puppet: '5.0.0' })
    end

    context 'and not provided with an object name' do
      it 'exits non-zero and prints the `pdk new test` help' do
        expect { PDK::CLI.run(['new', 'test', '--unit']) }.to exit_nonzero.and output(help_text).to_stdout
      end
    end

    context 'and provided an empty string as the object name' do
      it 'exits non-zero and prints the `pdk new test` help' do
        expect { PDK::CLI.run(['new', 'test', '--unit', '']) }.to exit_nonzero.and output(help_text).to_stdout
      end
    end

    context 'and provided an invalid object name' do
      before do
        allow(PDK::Util::PuppetStrings).to receive(:find_object).with('test-class').and_raise(PDK::Util::PuppetStrings::NoObjectError)
      end

      it 'exits with an error' do
        expect(logger).to receive(:error).with(a_string_matching(/unable to find anything called "test-class"/i))

        expect { PDK::CLI.run(['new', 'test', '--unit', 'test-class']) }.to exit_nonzero
      end
    end

    context 'and provided a valid object name' do
      let(:generator) { instance_double(PDK::Generate::PuppetClass, run: true) }

      before do
        allow(PDK::Util::PuppetStrings).to receive(:find_object).with('test_class').and_return([PDK::Generate::PuppetClass, { 'name' => 'my_module::test_class' }])
      end

      context 'and the test type is specified with --unit' do
        after do
          PDK::CLI.run(['new', 'test', '--unit', 'test_class'])
        end

        it 'generates a unit test for the class' do
          expect(PDK::Generate::PuppetClass).to receive(:new).with(anything, 'my_module::test_class', include(spec_only: true)).and_return(generator)
          expect(generator).to receive(:run)
        end
      end

      context 'and the test type is not specified' do
        after do
          PDK::CLI.run(['new', 'test', 'test_class'])
        end

        it 'generates a unit test for the class' do
          expect(PDK::Generate::PuppetClass).to receive(:new).with(anything, 'my_module::test_class', include(spec_only: true)).and_return(generator)
          expect(generator).to receive(:run)
        end
      end
    end

    context 'and provided a valid object name that PDK has no generator for' do
      before do
        allow(PDK::Util::PuppetStrings)
          .to receive(:find_object)
          .with('test_thing')
          .and_raise(PDK::Util::PuppetStrings::NoGeneratorError,
                     'unsupported_thing')
      end

      it 'exits with an error' do
        expect(logger).to receive(:error).with(a_string_matching(/pdk does not support generating unit tests for "unsupported_thing"/i))

        expect { PDK::CLI.run(['new', 'test', '--unit', 'test_thing']) }.to exit_nonzero
      end
    end
  end
end
