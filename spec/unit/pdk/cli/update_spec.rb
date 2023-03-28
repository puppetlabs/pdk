require 'spec_helper'
require 'pdk/cli'

describe 'PDK::CLI update' do
  let(:help_text) { a_string_matching(%r{^USAGE\s+pdk update}m) }
  let(:updater) do
    instance_double(PDK::Module::Update, run: true, current_version: current_version, new_version: new_version, pinned_to_puppetlabs_template_tag?: pinned_to_tag, template_uri: template_uri)
  end
  let(:current_version) { '1.2.3' }
  let(:new_version) { '1.2.4' }
  let(:module_pdk_version) { PDK::VERSION }
  let(:pinned_to_tag) { false }
  let(:template_uri) { PDK::Util::TemplateURI.new("pdk-default##{current_version}") }
  let(:module_root) { '/path/to/test/module' }

  context 'when not run from inside a module' do
    include_context 'run outside module'

    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(%r{can only be run from inside a valid module directory}))

      expect { PDK::CLI.run(['update']) }.to exit_nonzero
    end

    it 'does not submit the command to analytics' do
      expect(analytics).not_to receive(:screen_view)

      expect { PDK::CLI.run(['update']) }.to exit_nonzero
    end
  end

  context 'when run inside a nested module-looking directories' do
    # It is possible in a control repo to have a metadata.json in the root, but want to update a module
    # inside one of the module directories e.g.
    #
    #  control-repo
    #    +- metadata.json
    #    |
    #    +- site
    #         +- profile        (Current Directory)  <---- Want to update from here
    #              +- manifests
    #                 ....
    #
    around do |example|
      # We need the real methods here
      # rubocop:disable PDK/FileUtilsMkdirP
      # rubocop:disable PDK/FileUtilsRMRF
      require 'tmpdir'
      spec_dir = Dir.mktmpdir('pdk_update')
      # Create the control repo
      FileUtils.mkdir_p(File.join(spec_dir, 'site', 'profile', 'manifests'))
      File.write(
        File.join(spec_dir, 'metadata.json'),
        <<-EOT,
        {
          "name": "spec-foo",
          "version": "0.1.0",
          "author": "spec",
          "summary": "",
          "license": "Apache-2.0",
          "source": "",
          "dependencies": [],
          "operatingsystem_support": [],
          "requirements": [
            {
              "name": "puppet",
              "version_requirement": ">= 6.21.0 < 7.0.0"
            }
          ],
          "pdk-version": "99.99.0",
          "template-url": "https://github.com/puppetlabs/pdk-templates#main",
          "template-ref": "tags/99.99.0"
        }
        EOT
      )
      Dir.chdir(File.join(spec_dir, 'site', 'profile')) { example.run }
      FileUtils.rm_rf(spec_dir)
      # rubocop:enable PDK/FileUtilsMkdirP
      # rubocop:enable PDK/FileUtilsRMRF
    end

    before do
      # Undo some of the mock_configuration mocking
      allow(PDK::Util::Filesystem).to receive(:file?).and_call_original
      # Ensure the the module update never actually happens
      allow(PDK::Module::Update).to receive(:new).with(module_root, anything).and_return(updater)
      # Reset cached information
      PDK.instance_variable_set(:@context, nil)
      allow(PDK).to receive(:context).and_call_original
    end

    it 'uses the nested module directory' do
      expect(PDK::Module::Update).to receive(:new).with(Dir.pwd, anything).and_return(updater)

      expect { PDK::CLI.run(['update', '--force']) }.not_to raise_error(StandardError)
    end
  end

  context 'when run from inside a module' do
    let(:pdk_context) { PDK::Context::Module.new(module_root, module_root) }

    before do
      allow(PDK).to receive(:context).and_return(pdk_context)
      allow(PDK::Util).to receive(:module_root).and_return(module_root)
      allow(PDK::Util).to receive(:module_pdk_compatible?).and_return(true)
      allow(PDK::Util).to receive(:module_pdk_version).and_return(module_pdk_version)
    end

    context 'and provided no flags' do
      after do
        PDK::CLI.run(['update'])
      end

      it 'invokes the updater with no options' do
        expect(PDK::Module::Update).to receive(:new) { |_, opts|
          expect(opts[:noop]).to be false if opts.key?(:noop)
          expect(opts[:force]).to be false if opts.key?(:false) # rubocop:disable Lint/BooleanSymbol
          expect(opts).not_to include(:'template-ref')
        }.and_return(updater)

        expect(updater).to receive(:run)
      end

      it 'submits the command to analytics' do
        allow(PDK::Module::Update).to receive(:new).with(module_root, anything).and_return(updater)

        expect(analytics).to receive(:screen_view).with(
          'update',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and the module is pinned to tagged version of our template' do
      after do
        PDK::CLI.run(['update'])
      end

      before do
        allow(PDK::Module::Update).to receive(:new).with(module_root, any_args).and_return(updater)
        allow(updater).to receive(:run)
      end

      let(:pinned_to_tag) { true }

      it 'informs the user that the template is pinned' do
        expect(logger).to receive(:info).with(a_string_matching(%r{module is currently pinned}i))
      end
    end

    context 'and the --noop flag has been passed' do
      after do
        PDK::CLI.run(['update', '--noop'])
      end

      it 'passes the noop option through to the updater' do
        expect(PDK::Module::Update).to receive(:new).with(module_root, hash_including(noop: true)).and_return(updater)
        expect(updater).to receive(:run)
      end

      it 'submits the command to analytics' do
        allow(PDK::Module::Update).to receive(:new).with(module_root, anything).and_return(updater)

        expect(analytics).to receive(:screen_view).with(
          'update',
          cli_options: 'noop=true',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and the --force flag has been passed' do
      after do
        PDK::CLI.run(['update', '--force'])
      end

      it 'passes the force option through to the updater' do
        expect(PDK::Module::Update).to receive(:new).with(module_root, hash_including(force: true)).and_return(updater)
        expect(updater).to receive(:run)
      end

      it 'submits the command to analytics' do
        allow(PDK::Module::Update).to receive(:new).with(module_root, anything).and_return(updater)

        expect(analytics).to receive(:screen_view).with(
          'update',
          cli_options: 'force=true',
          output_format: 'default',
          ruby_version: RUBY_VERSION,
        )
      end
    end

    context 'and the --force and --noop flags have been passed' do
      it 'exits with an error' do
        expect(logger).to receive(:error).with(a_string_matching(%r{can not specify --noop and --force}i))

        expect { PDK::CLI.run(['update', '--noop', '--force']) }.to exit_nonzero
      end

      it 'does not submit the command to analytics' do
        expect(analytics).not_to receive(:screen_view)

        expect { PDK::CLI.run(['update', '--noop', '--force']) }.to exit_nonzero
      end
    end

    context 'and the module metadata specifies a newer PDK version' do
      let(:module_pdk_version) { '999.9.9' }

      context 'and the --force flag has not been passed' do
        it 'warns the user and then aborts' do
          expect(logger).to receive(:warn).with(a_string_matching(%r{newer than your PDK version}i))
          expect(logger).to receive(:error).with(a_string_matching(%r{update your PDK installation}i))

          expect { PDK::CLI.run(['update']) }.to exit_nonzero
        end
      end

      context 'and the --force flag has been passed' do
        it 'warns the user and then continues' do
          allow(PDK::Module::Update).to receive(:new).with(module_root, hash_including(force: true)).and_return(updater)
          expect(logger).to receive(:warn).with(a_string_matching(%r{newer than your PDK version}i))

          PDK::CLI.run(['update', '--force'])
        end
      end
    end
  end

  context 'when run from inside an unconverted module' do
    before do
      allow(PDK::Util).to receive(:module_root).and_return(module_root)
      allow(PDK::Util).to receive(:module_pdk_compatible?).and_return(false)
    end

    context 'and provided no flags' do
      it 'raises ExitWithError' do
        expect(logger).to receive(:error).with(a_string_matching(%r{This module does not appear to be PDK compatible}i))

        expect { PDK::CLI.run(['update']) }.to exit_nonzero
      end

      it 'does not submit the command to analytics' do
        expect(analytics).not_to receive(:screen_view)

        expect { PDK::CLI.run(['update']) }.to exit_nonzero
      end
    end
  end
end
