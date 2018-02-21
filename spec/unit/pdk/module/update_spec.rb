require 'spec_helper'
require 'pdk/module/update'

describe PDK::Module::Update do
  let(:options) { {} }
  let(:mock_metadata) do
    instance_double(
      PDK::Module::Metadata,
      data: {
        'template-url' => template_url,
        'template-ref' => template_ref,
      },
    )
  end
  let(:template_url) { 'https://github.com/puppetlabs/pdk-templates' }
  let(:template_ref) { nil }

  shared_context 'with mock metadata' do
    before(:each) do
      allow(PDK::Module::Metadata).to receive(:from_file).with('metadata.json').and_return(mock_metadata)
    end
  end

  shared_context 'requires bundle install' do
    context 'if the Gemfile is updated' do
      before(:each) do
        allow(instance).to receive(:needs_bundle_update?).and_return(true)
        allow(instance.update_manager).to receive(:remove_file)
        allow(PDK::Util::Bundler).to receive(:ensure_bundle!)
      end

      it 'removes the existing Gemfile.lock' do
        expect(instance.update_manager).to receive(:remove_file).with('Gemfile.lock')
      end

      it 'removes the bundler project config' do
        expect(instance.update_manager).to receive(:remove_file).with(File.join('.bundle', 'config'))
      end

      it 'triggers a bundle install' do
        expect(PDK::Util::Bundler).to receive(:ensure_bundle!)
      end
    end
  end

  describe '#run' do
    let(:instance) { described_class.new(options) }
    let(:template_ref) { '1.3.2-0-g1234567' }
    let(:changes) { true }

    include_context 'with mock metadata'

    before(:each) do
      allow(instance).to receive(:stage_changes!)
      allow(instance).to receive(:print_summary)
      allow(instance).to receive(:new_version).and_return('1.4.0')
      allow(instance).to receive(:print_result)
      allow(instance.update_manager).to receive(:sync_changes!)
      allow(instance.update_manager).to receive(:changes?).and_return(changes)
    end

    after(:each) do
      instance.run
    end

    context 'when the version is the same' do
      let(:options) { { noop: true } }

      before(:each) do
        allow(instance).to receive(:current_version).and_return('1.4.0')
      end

      context 'but there are changes' do
        let(:changes) { true }

        it 'doesn\'t print message' do
          expect(logger).not_to receive(:info).with(a_string_matching(%r{This module is already up to date with version 1.4.0 of the template}i))
        end
      end

      context 'but there are no changes' do
        let(:changes) { false }

        it 'doesn\'t print message' do
          expect(logger).to receive(:info).with(a_string_matching(%r{This module is already up to date with version 1.4.0 of the template}))
        end
      end
    end

    context 'when using the default template' do
      let(:options) { { noop: true } }
      let(:template_url) { PDK::Util.default_template_url }

      it 'refers to the template as the default template' do
        expect(logger).to receive(:info).with(a_string_matching(%r{using the default template}i))
      end
    end

    context 'when using a custom template' do
      let(:options) { { noop: true } }
      let(:template_url) { 'https://my/custom/template' }

      it 'refers to the template by its URL or path' do
        expect(logger).to receive(:info).with(a_string_matching(%r{using the template at #{Regexp.escape(template_url)}}i))
      end
    end

    context 'when running in noop mode' do
      let(:options) { { noop: true } }

      it 'does not prompt the user to make the changes' do
        expect(PDK::CLI::Util).not_to receive(:prompt_for_yes)
      end

      it 'does not sync the pending changes' do
        expect(instance.update_manager).not_to receive(:sync_changes!)
      end
    end

    context 'when not running in noop mode' do
      context 'with force' do
        let(:options) { { force: true } }

        it 'does not prompt the user to make the changes' do
          expect(PDK::CLI::Util).not_to receive(:prompt_for_yes)
        end

        it 'syncs the pending changes' do
          expect(instance.update_manager).to receive(:sync_changes!)
        end

        include_context 'requires bundle install'
      end

      context 'without force' do
        it 'prompts the user to make the changes' do
          expect(PDK::CLI::Util).to receive(:prompt_for_yes)
        end

        context 'if the user chooses to continue' do
          before(:each) do
            allow(PDK::CLI::Util).to receive(:prompt_for_yes).and_return(true)
          end

          it 'syncs the pending changes' do
            expect(instance.update_manager).to receive(:sync_changes!)
          end

          it 'prints the result' do
            expect(instance).to receive(:print_result)
          end

          include_context 'requires bundle install'
        end

        context 'if the user chooses not to continue' do
          before(:each) do
            allow(PDK::CLI::Util).to receive(:prompt_for_yes).and_return(false)
          end

          it 'does not sync the pending changes' do
            expect(instance.update_manager).not_to receive(:sync_changes!)
          end

          it 'does not print the result' do
            expect(instance).not_to receive(:print_result)
          end
        end
      end
    end
  end

  describe '#module_metadata' do
    subject(:result) { described_class.new(options).module_metadata }

    context 'when the metadata.json can be read' do
      include_context 'with mock metadata'

      it 'returns the metadata object' do
        is_expected.to eq(mock_metadata)
      end
    end

    context 'when the metadata.json can not be read' do
      before(:each) do
        allow(PDK::Module::Metadata).to receive(:from_file).with('metadata.json').and_raise(ArgumentError, 'some error')
      end

      it 'raises an ExitWithError exception' do
        expect { -> { result }.call }.to raise_error(PDK::CLI::ExitWithError, %r{some error}i)
      end
    end
  end

  describe '#template_url' do
    subject { described_class.new(options).template_url }

    include_context 'with mock metadata'

    it 'returns the template-url value from the module metadata' do
      is_expected.to eq('https://github.com/puppetlabs/pdk-templates')
    end
  end

  describe '#current_version' do
    subject { described_class.new(options).current_version }

    include_context 'with mock metadata'

    context 'when the template-ref describes a git tag' do
      let(:template_ref) { '1.3.2-0-g07678c8' }

      it 'returns the tag name' do
        is_expected.to eq('1.3.2@07678c8')
      end
    end

    context 'when the template-ref describes a branch commit' do
      let(:template_ref) { 'heads/master-4-g1234abc' }

      it 'returns the branch name and the commit SHA' do
        is_expected.to eq('master@1234abc')
      end
    end
  end

  describe '#new_version' do
    subject { described_class.new(options).new_version }

    include_context 'with mock metadata'

    context 'when the default_template_ref specifies a tag' do
      before(:each) do
        allow(PDK::Util).to receive(:default_template_ref).and_return('1.4.0')
      end

      it 'returns the tag name' do
        is_expected.to eq('1.4.0')
      end
    end

    context 'when the default_template_ref specifies a branch head' do
      before(:each) do
        allow(PDK::Util).to receive(:default_template_ref).and_return('origin/master')
        allow(PDK::Util::Git).to receive(:ls_remote)
          .with(template_url, 'refs/heads/master')
          .and_return('3cdd84e8f0aae30bf40d15556482fc8752899312')
      end

      include_context 'with mock metadata'
      let(:template_ref) { 'heads/master-0-g07678c8' }

      it 'returns the branch name and the commit SHA' do
        is_expected.to eq('master@3cdd84e')
      end
    end
  end
end
