require 'spec_helper'
require 'pdk/cli'

describe 'PDK::CLI convert' do
  include_context 'mock configuration'

  let(:help_text) { a_string_matching(%r{^USAGE\s+pdk convert}m) }
  let(:pdk_context) { PDK::Context::Module.new(module_root, module_root) }
  let(:module_root) { '/path/to/test/module' }

  before(:each) do
    allow(PDK::Util).to receive(:package_install?).and_return(false)
    allow(PDK).to receive(:context).and_return(pdk_context)
  end

  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(%r{can only be run from inside a valid module directory}))

      expect { PDK::CLI.run(['convert']) }.to exit_nonzero
    end

    it 'does not submit the command to analytics' do
      expect(analytics).not_to receive(:screen_view)

      expect { PDK::CLI.run(['convert']) }.to exit_nonzero
    end
  end

  context 'when run inside a nested module-looking directories' do
    # It is possible in a control repo to have a metadata.json in the root, but want to convert a module
    # inside one of the module directories e.g.
    #
    #  control-repo
    #    +- metadata.json
    #    |
    #    +- site
    #         +- profile        (Current Directory)  <---- Want to convert from here
    #              +- manifests
    #                 ....
    #
    around(:each) do |example|
      # We need the real methods here
      # rubocop:disable PDK/FileUtilsMkdirP
      # rubocop:disable PDK/FileUtilsRMRF
      require 'tmpdir'
      current_dir = Dir.pwd
      spec_dir = Dir.mktmpdir('pdk_convert')
      Dir.chdir(spec_dir)
      # Create the control repo
      FileUtils.mkdir_p(File.join('site', 'profile', 'manifests'))
      File.write('metadata.json', '{}')
      Dir.chdir(File.join('site', 'profile'))

      example.run

      Dir.chdir(current_dir)
      FileUtils.rm_rf(spec_dir)
      # rubocop:enable PDK/FileUtilsMkdirP
      # rubocop:enable PDK/FileUtilsRMRF
    end

    before(:each) do
      # Undo some of the mock_configuration mocking
      allow(PDK::Util::Filesystem).to receive(:file?).and_call_original
      # Reset cached information
      PDK.instance_variable_set(:@context, nil)
      allow(PDK).to receive(:context).and_call_original
    end

    it 'uses the nested module directory' do
      expect(PDK::Module::Convert).to receive(:invoke).with(Dir.pwd, anything)

      expect { PDK::CLI.run(['convert']) }.not_to raise_error(StandardError)
    end
  end

  context 'when run from inside a module' do
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return(module_root)
      allow(PDK::Module::Convert).to receive(:invoke)
    end

    context 'and provided no flags' do
      after(:each) do
        PDK::CLI.run(['convert'])
      end

      it 'invokes the converter with no template specified' do
        expect(PDK::Module::Convert).to receive(:invoke).with(module_root, hash_not_including(:'template-url'))
      end

      it 'submits the command to analytics' do
        expect(analytics).to receive(:screen_view).with(
          'convert',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and the --template-url option has been passed' do
      after(:each) do
        PDK::CLI.run(['convert', '--template-url', 'https://my/template'])
      end

      it 'invokes the converter with the user supplied template' do
        expect(PDK::Module::Convert).to receive(:invoke).with(module_root, hash_including('template-url': 'https://my/template'))
      end

      it 'submits the command to analytics' do
        expect(analytics).to receive(:screen_view).with(
          'convert',
          cli_options: 'template-url=redacted',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and the --template-ref option has been passed' do
      after(:each) do
        PDK::CLI.run(['convert', '--template-url', 'https://my/template', '--template-ref', '1.0.0'])
      end

      it 'invokes the converter with the user supplied template' do
        expect(PDK::Module::Convert).to receive(:invoke).with(module_root, hash_including('template-url': 'https://my/template', 'template-ref': '1.0.0'))
      end

      it 'submits the command to analytics' do
        expect(analytics).to receive(:screen_view).with(
          'convert',
          cli_options: 'template-url=redacted,template-ref=redacted',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and the --noop flag has been passed' do
      after(:each) do
        PDK::CLI.run(['convert', '--noop'])
      end

      it 'passes the noop option through to the converter' do
        expect(PDK::Module::Convert).to receive(:invoke).with(module_root, hash_including(noop: true))
      end

      it 'submits the command to analytics' do
        expect(analytics).to receive(:screen_view).with(
          'convert',
          cli_options: 'noop=true',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and the --force flag has been passed' do
      after(:each) do
        PDK::CLI.run(['convert', '--force'])
      end

      it 'passes the force option through to the converter' do
        expect(PDK::Module::Convert).to receive(:invoke).with(module_root, hash_including(force: true))
      end

      it 'submits the command to analytics' do
        expect(analytics).to receive(:screen_view).with(
          'convert',
          cli_options: 'force=true',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and the --force and --noop flags have been passed' do
      it 'exits with an error' do
        expect(logger).to receive(:error).with(a_string_matching(%r{can not specify --noop and --force}i))

        expect { PDK::CLI.run(['convert', '--noop', '--force']) }.to exit_nonzero
      end

      it 'does not submit the command to analytics' do
        expect(analytics).not_to receive(:screen_view)

        expect { PDK::CLI.run(['convert', '--noop', '--force']) }.to exit_nonzero
      end
    end

    context 'and the --skip-interview flag has been passed' do
      after(:each) do
        PDK::CLI.run(['convert', '--skip-interview'])
      end

      it 'passes the skip-interview option through to the converter' do
        expect(PDK::Module::Convert).to receive(:invoke).with(module_root, hash_including('skip-interview': true))
      end

      it 'submits the command to analytics' do
        expect(analytics).to receive(:screen_view).with(
          'convert',
          cli_options: 'skip-interview=true',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and the --full-interview flag has been passed' do
      after(:each) do
        PDK::CLI.run(['convert', '--full-interview'])
      end

      it 'passes the full-interview option through to the converter' do
        expect(PDK::Module::Convert).to receive(:invoke).with(module_root, hash_including('full-interview': true))
      end

      it 'submits the command to analytics' do
        expect(analytics).to receive(:screen_view).with(
          'convert',
          cli_options: 'full-interview=true',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and the --skip-interview and --full-interview flags have been passed' do
      after(:each) do
        PDK::CLI.run(['convert', '--skip-interview', '--full-interview'])
      end

      it 'ignores full-interview and continues with a log message' do
        expect(logger).to receive(:info).with(a_string_matching(%r{Ignoring --full-interview and continuing with --skip-interview.}i))
        expect(PDK::Module::Convert).to receive(:invoke).with(module_root, hash_including('skip-interview': true, 'full-interview': false))
      end

      it 'submits the command to analytics' do
        expect(analytics).to receive(:screen_view).with(
          'convert',
          cli_options: 'skip-interview=true,full-interview=true',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and the --force and --full-interview flags have been passed' do
      after(:each) do
        PDK::CLI.run(['convert', '--force', '--full-interview'])
      end

      it 'ignores full-interview and continues with a log message' do
        expect(logger).to receive(:info).with(a_string_matching(%r{Ignoring --full-interview and continuing with --force.}i))
        expect(PDK::Module::Convert).to receive(:invoke).with(module_root, hash_including(force: true, 'full-interview': false))
      end

      it 'submits the command to analytics' do
        expect(analytics).to receive(:screen_view).with(
          'convert',
          cli_options: 'force=true,full-interview=true',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and the --default-template flag has been passed' do
      let(:args) { ['convert', '--default-template'] }

      context 'with the --template-url option' do
        let(:args) { super() + ['--template-url', 'https://some/template'] }

        it 'exits with an error' do
          msg = %r{can not specify --template-url and --default-template}i
          expect(logger).to receive(:error).with(a_string_matching(msg))

          expect { PDK::CLI.run(args) }.to exit_nonzero
        end

        it 'does not submit the command to analytics' do
          expect(analytics).not_to receive(:screen_view)

          expect { PDK::CLI.run(args) }.to exit_nonzero
        end
      end

      context 'without the --template-url option' do
        subject(:run) { PDK::CLI.run(args) }

        it 'converts the module to the default template' do
          expected_template = PDK::Util::TemplateURI.default_template_addressable_uri.to_s

          expect(PDK::Module::Convert).to receive(:invoke)
            .with(module_root, hash_including('template-url': expected_template))
          run
        end

        it 'clears the saved template-url answer' do
          run
          expect(PDK.config.get(['user', 'module_defaults', 'template-url'])).to be_nil
        end

        it 'submits the command to analytics' do
          expect(analytics).to receive(:screen_view).with(
            'convert',
            cli_options: 'default-template=true,template-url=redacted',
            output_format: 'default',
            ruby_version: RUBY_VERSION,
          )
          run
        end
      end
    end
  end
end
