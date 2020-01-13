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
      expect(logger).to receive(:error).with(a_string_matching(%r{must be run from inside a valid module}))

      expect { PDK::CLI.run(%w[update]) }.to exit_nonzero
    end

    it 'does not submit the command to analytics' do
      expect(analytics).not_to receive(:screen_view)

      expect { PDK::CLI.run(%w[update]) }.to exit_nonzero
    end
  end

  context 'when run from inside a module' do
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return(module_root)
      allow(PDK::Util).to receive(:module_pdk_compatible?).and_return(true)
      allow(PDK::Util).to receive(:module_pdk_version).and_return(module_pdk_version)
    end

    context 'and provided no flags' do
      after(:each) do
        PDK::CLI.run(%w[update])
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
          ruby_version:  RUBY_VERSION,
        )
      end
    end

    context 'and the module is pinned to tagged version of our template' do
      after(:each) do
        PDK::CLI.run(%w[update])
      end

      before(:each) do
        allow(PDK::Module::Update).to receive(:new).with(module_root, any_args).and_return(updater)
        allow(updater).to receive(:run)
      end

      let(:pinned_to_tag) { true }

      it 'informs the user that the template is pinned' do
        expect(logger).to receive(:info).with(a_string_matching(%r{module is currently pinned}i))
      end
    end

    context 'and the --noop flag has been passed' do
      after(:each) do
        PDK::CLI.run(%w[update --noop])
      end

      it 'passes the noop option through to the updater' do
        expect(PDK::Module::Update).to receive(:new).with(module_root, hash_including(noop: true)).and_return(updater)
        expect(updater).to receive(:run)
      end

      it 'submits the command to analytics' do
        allow(PDK::Module::Update).to receive(:new).with(module_root, anything).and_return(updater)

        expect(analytics).to receive(:screen_view).with(
          'update',
          cli_options:   'noop=true',
          output_format: 'default',
          ruby_version:  RUBY_VERSION,
        )
      end
    end

    context 'and the --force flag has been passed' do
      after(:each) do
        PDK::CLI.run(%w[update --force])
      end

      it 'passes the force option through to the updater' do
        expect(PDK::Module::Update).to receive(:new).with(module_root, hash_including(force: true)).and_return(updater)
        expect(updater).to receive(:run)
      end

      it 'submits the command to analytics' do
        allow(PDK::Module::Update).to receive(:new).with(module_root, anything).and_return(updater)

        expect(analytics).to receive(:screen_view).with(
          'update',
          cli_options:   'force=true',
          output_format: 'default',
          ruby_version:  RUBY_VERSION,
        )
      end
    end

    context 'and the --force and --noop flags have been passed' do
      it 'exits with an error' do
        expect(logger).to receive(:error).with(a_string_matching(%r{can not specify --noop and --force}i))

        expect { PDK::CLI.run(%w[update --noop --force]) }.to exit_nonzero
      end

      it 'does not submit the command to analytics' do
        expect(analytics).not_to receive(:screen_view)

        expect { PDK::CLI.run(%w[update --noop --force]) }.to exit_nonzero
      end
    end

    context 'and the module metadata specifies a newer PDK version' do
      let(:module_pdk_version) { '999.9.9' }

      context 'and the --force flag has not been passed' do
        it 'warns the user and then aborts' do
          expect(logger).to receive(:warn).with(a_string_matching(%r{newer than your PDK version}i))
          expect(logger).to receive(:error).with(a_string_matching(%r{update your PDK installation}i))

          expect { PDK::CLI.run(%w[update]) }.to exit_nonzero
        end
      end

      context 'and the --force flag has been passed' do
        it 'warns the user and then continues' do
          allow(PDK::Module::Update).to receive(:new).with(module_root, hash_including(force: true)).and_return(updater)
          expect(logger).to receive(:warn).with(a_string_matching(%r{newer than your PDK version}i))

          PDK::CLI.run(%w[update --force])
        end
      end
    end
  end

  context 'when run from inside an unconverted module' do
    before(:each) do
      allow(PDK::Util).to receive(:module_root).and_return(module_root)
      allow(PDK::Util).to receive(:module_pdk_compatible?).and_return(false)
    end

    context 'and provided no flags' do
      it 'raises ExitWithError' do
        expect(logger).to receive(:error).with(a_string_matching(%r{This module does not appear to be PDK compatible}i))

        expect { PDK::CLI.run(%w[update]) }.to exit_nonzero
      end

      it 'does not submit the command to analytics' do
        expect(analytics).not_to receive(:screen_view)

        expect { PDK::CLI.run(%w[update]) }.to exit_nonzero
      end
    end
  end
end
