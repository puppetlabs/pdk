require 'spec_helper'
require 'pdk/module/convert'

describe PDK::Module::Convert do
  shared_examples_for 'it interviews the user for the metadata' do
    it 'interviews the user for the metadata' do
      expect(PDK::Generate::Module).to receive(:prepare_metadata).and_return(PDK::Module::Metadata.new)
      described_class.new.update_metadata(metadata_path, template_metadata)
    end

    it 'updates the metadata with information about the template used to convert the module' do
      allow(PDK::Generate::Module).to receive(:prepare_metadata).and_return(PDK::Module::Metadata.new)
      expect(updated_metadata).to include('template-url' => 'http://my.test/template.git', 'template-ref' => 'v1.2.3')
    end
  end

  shared_context 'prompt to continue' do |value|
    before(:each) do
      allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(value)
    end
  end

  shared_context 'no changes in the summary' do
    before(:each) do
      allow($stdout).to receive(:puts).with(%r{No changes required})
    end
  end

  shared_context 'has changes in the summary' do
    before(:each) do
      allow($stdout).to receive(:puts).with("\n----------------------------------------")
    end
  end

  shared_context 'added files in the summary' do
    before(:each) do
      allow($stdout).to receive(:puts).with(%r{-Files to be added-}i)
    end
  end

  shared_context 'modified files in the summary' do
    before(:each) do
      allow($stdout).to receive(:puts).with(%r{-Files to be modified-}i)
    end
  end

  shared_context 'removed files in the summary' do
    before(:each) do
      allow($stdout).to receive(:puts).with(%r{-Files to be removed-}i)
    end
  end

  shared_context 'outputs a convert report' do
    before(:each) do
      allow($stdout).to receive(:puts).with(%r{You can find detailed differences in convert_report.txt.})
    end
  end

  shared_context 'completes a convert' do
    before(:each) do
      allow($stdout).to receive(:puts).with(%r{-Convert completed-}i)
    end
  end

  describe '.invoke' do
    let(:options) { { noop: true } }
    let(:mock_instance) { instance_double(described_class) }

    it 'instantiates a new object with the provided options and calls #run' do
      allow(described_class).to receive(:new).with(options).and_return(mock_instance)
      expect(mock_instance).to receive(:run)

      described_class.invoke(options)
    end
  end

  describe '.new', after_hook: true do
    let(:instance) { described_class.new(options) }
    let(:options) { {} }
    let(:update_manager) { instance_double(PDK::Module::UpdateManager, sync_changes!: true) }
    let(:template_dir) { instance_double(PDK::Module::TemplateDir, metadata: {}) }
    let(:metadata) { instance_double(PDK::Module::Metadata, data: {}) }
    let(:template_files) { { path: 'a/path/to/file', content: 'file contents', status: :manage } }
    let(:added_files) { Set.new }
    let(:removed_files) { Set.new }
    let(:modified_files) { {} }

    before(:each) do
      changes = { added: added_files, removed: removed_files, modified: modified_files }

      allow(PDK::Module::UpdateManager).to receive(:new).and_return(update_manager)
      allow(instance).to receive(:update_metadata).with(any_args).and_return(metadata)
      allow(PDK::Module::TemplateDir).to receive(:new).with(anything, anything, anything).and_yield(template_dir)
      allow(PDK::Util::Git).to receive(:repo?).with(anything).and_return(true)
      allow(template_dir).to receive(:module_metadata=)
      allow(template_dir).to receive(:render).and_yield(template_files[:path], template_files[:content], template_files[:status])
      allow(update_manager).to receive(:changes).and_return(changes)
      allow(update_manager).to receive(:changed?).with('Gemfile').and_return(false)
    end

    after(:each, after_hook: true) do
      instance.run
      FileUtils.rm_f('convert_report.txt')
    end

    context 'when an error is raised from TemplateDir', after_hook: false do
      before(:each) do
        allow(PDK::Module::TemplateDir).to receive(:new)
          .with(any_args).and_raise(ArgumentError, 'The specified template is not a directory')
      end

      it 'reraises the error as a CLI error' do
        expect {
          instance.run
        }.to raise_error(PDK::CLI::ExitWithError, 'The specified template is not a directory')
      end
    end

    context 'when there are no changes to apply' do
      include_context 'no changes in the summary'

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:exist?).with('a/path/to/file').and_return(true)
        allow(update_manager).to receive(:changes?).and_return(false)
        allow(template_dir).to receive(:render)
        allow(PDK::Module::TemplateDir).to receive(:files_in_template).and_return({})

        allow(update_manager).to receive(:add_file).with('metadata.json', anything)
      end

      it 'returns without syncing the changes' do
        expect(update_manager).not_to receive(:sync_changes!)
      end

      context 'and it is to add tests' do
        let(:options) { { :'add-tests' => true } }

        context 'and there are tests to add' do
          before(:each) do
            allow(instance).to receive(:missing_tests?).and_return(true)
          end

          it 'attempts to add missing tests' do
            expect(instance).to receive(:add_tests!)
          end
        end

        context 'and there are no tests to add' do
          before(:each) do
            allow(instance).to receive(:missing_tests?).and_return(false)
          end

          it 'does not attempt to add missing tests' do
            expect(instance).not_to receive(:add_tests!)
          end
        end
      end
    end

    context 'when the Gemfile has been modified' do
      include_context 'has changes in the summary'
      include_context 'modified files in the summary'
      include_context 'outputs a convert report'
      include_context 'prompt to continue', true
      include_context 'completes a convert'

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:exist?).with('a/path/to/file').and_return(true)
        allow(update_manager).to receive(:modify_file).with(any_args)
        allow(update_manager).to receive(:changes?).and_return(true)
        allow($stdout).to receive(:puts).with(['Gemfile'])

        allow(update_manager).to receive(:add_file).with('metadata.json', anything)
        allow(update_manager).to receive(:modify_file).with(template_files[:path], template_files[:content])
        allow($stdout).to receive(:puts).with(%r{1 files modified})
        allow(update_manager).to receive(:changed?).with('Gemfile').and_return(true)
        allow(update_manager).to receive(:remove_file).with(anything)
        allow(update_manager).to receive(:unlink_file).with(anything)
        allow(PDK::Util::Bundler).to receive(:ensure_bundle!)
        allow($stdout).to receive(:puts).with(%r{You can find a report of differences in convert_report.txt.})
      end

      let(:modified_files) do
        {
          'Gemfile' => 'a diff',
        }
      end

      it 'removes the old Gemfile.lock' do
        expect(update_manager).to receive(:unlink_file).with('Gemfile.lock')
      end

      it 'removes the old bundler config' do
        expect(update_manager).to receive(:unlink_file).with(File.join('.bundle', 'config'))
      end

      it 'updates the bundled gems' do
        expect(PDK::Util::Bundler).to receive(:ensure_bundle!)
      end
    end

    context 'when there are changes to apply' do
      include_context 'has changes in the summary'
      include_context 'modified files in the summary'
      include_context 'outputs a convert report'
      include_context 'completes a convert'

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:exist?).with('a/path/to/file').and_return(true)
        allow(update_manager).to receive(:modify_file).with(any_args)
        allow(update_manager).to receive(:changes?).and_return(true)
        allow($stdout).to receive(:puts).with(['some/file'])

        allow(update_manager).to receive(:add_file).with('metadata.json', anything)
        allow(update_manager).to receive(:modify_file).with(template_files[:path], template_files[:content])
        allow($stdout).to receive(:puts).with(%r{1 files modified})
        allow($stdout).to receive(:puts).with(%r{You can find a report of differences in convert_report.txt.})
      end

      let(:modified_files) do
        {
          'some/file' => 'a diff',
        }
      end

      context 'and run normally' do
        include_context 'prompt to continue', false

        it 'prints a diff of the changed files' do
          expect($stdout).to receive(:puts).with(['some/file'])
        end

        it 'prompts the user to continue' do
          expect(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(false)
        end

        context 'if the user chooses to continue' do
          include_context 'prompt to continue', true

          it 'syncs the pending changes' do
            expect(update_manager).to receive(:sync_changes!)
          end

          context 'and it is to add tests' do
            let(:options) { { :'add-tests' => true } }

            context 'and there are tests to add' do
              before(:each) do
                allow(instance).to receive(:missing_tests?).and_return(true)
              end

              it 'attempts to add missing tests' do
                expect(instance).to receive(:add_tests!)
              end
            end

            context 'and there are no tests to add' do
              before(:each) do
                allow(instance).to receive(:missing_tests?).and_return(false)
              end

              it 'does not attempt to add missing tests' do
                expect(instance).not_to receive(:add_tests!)
              end
            end
          end
        end

        context 'if the user chooses not to continue' do
          it 'does not sync the changes' do
            expect(update_manager).not_to receive(:sync_changes!)
          end

          it 'does not attempt to add missing tests' do
            expect(instance).not_to receive(:add_tests!)
          end
        end
      end

      context 'and run in noop mode' do
        let(:options) { { noop: true } }

        it 'prints a diff of the changed files' do
          expect($stdout).to receive(:puts).with(['some/file'])
        end

        it 'does not prompt the user to continue' do
          expect(PDK::CLI::Util).not_to receive(:prompt_for_yes)
        end

        it 'does not sync the changes' do
          expect(update_manager).not_to receive(:sync_changes!)
        end

        it 'does not attempt to add missing tests' do
          expect(instance).not_to receive(:add_tests!)
        end
      end

      context 'and run in force mode' do
        let(:options) { { force: true } }

        it 'prints a diff of the changed files' do
          expect($stdout).to receive(:puts).with(['some/file'])
        end

        it 'does not prompt the user to continue' do
          expect(PDK::CLI::Util).not_to receive(:prompt_for_yes)
        end

        it 'syncs the pending changes' do
          expect(update_manager).to receive(:sync_changes!)
        end

        context 'and it is to add tests' do
          let(:options) { super().merge(:'add-tests' => true) }

          context 'and there are tests to add' do
            before(:each) do
              allow(instance).to receive(:missing_tests?).and_return(true)
            end

            it 'attempts to add missing tests' do
              expect(instance).to receive(:add_tests!)
            end
          end

          context 'and there are no tests to add' do
            before(:each) do
              allow(instance).to receive(:missing_tests?).and_return(false)
            end

            it 'does not attempt to add missing tests' do
              expect(instance).not_to receive(:add_tests!)
            end
          end
        end
      end
    end

    context 'when there are init files to add' do
      let(:options) { { noop: true } }
      let(:template_files) do
        { path: 'a/path/to/file', content: 'file contents', status: :init }
      end

      context 'and the files already exist' do
        include_context 'no changes in the summary'

        before(:each) do
          allow(PDK::Util::Filesystem).to receive(:exist?).with(template_files[:path]).and_return(true)
          allow(update_manager).to receive(:changes?).and_return(false)
        end

        it 'does not stage the file for addition' do
          expect(update_manager).not_to receive(:add_file).with(template_files[:path], anything)
        end
      end

      context 'and the files do not exist' do
        before(:each) do
          allow(PDK::Util::Filesystem).to receive(:exist?).with(template_files[:path]).and_return(false)
          allow(update_manager).to receive(:changes?).and_return(true)
          allow(update_manager).to receive(:add_file)
        end

        it 'stages the file for addition' do
          expect(update_manager).to receive(:add_file).with(template_files[:path], template_files[:content])
        end
      end
    end

    context 'when there are files to add' do
      include_context 'has changes in the summary'
      include_context 'added files in the summary'
      include_context 'outputs a convert report'
      include_context 'completes a convert'

      let(:added_files) do
        Set.new(
          [{
            path:    'path/to/file',
            content: 'file contents',
          }],
        )
      end

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:exist?).with('a/path/to/file').and_return(false)
        allow(update_manager).to receive(:changes?).and_return(true)
        allow($stdout).to receive(:puts).with(['path/to/file'])

        allow(update_manager).to receive(:add_file).with('metadata.json', anything)
        allow(update_manager).to receive(:add_file).with(template_files[:path], template_files[:content])
        allow($stdout).to receive(:puts).with(%r{1 files added})
        allow($stdout).to receive(:puts).with(%r{You can find a report of differences in convert_report.txt.})
      end

      context 'and run normally' do
        include_context 'prompt to continue', false

        it 'prints a path of the added files' do
          expect($stdout).to receive(:puts).with(['path/to/file'])
        end

        it 'prompts the user to continue' do
          expect(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(false)
        end

        context 'if the user chooses to continue' do
          include_context 'prompt to continue', true

          it 'syncs the pending changes' do
            expect(update_manager).to receive(:sync_changes!)
          end
        end

        context 'if the user chooses not to continue' do
          it 'does not sync the changes' do
            expect(update_manager).not_to receive(:sync_changes!)
          end
        end
      end

      context 'and run in noop mode' do
        let(:options) { { noop: true } }

        it 'prints a path of the added files' do
          expect($stdout).to receive(:puts).with(['path/to/file'])
        end

        it 'does not prompt the user to continue' do
          expect(PDK::CLI::Util).not_to receive(:prompt_for_yes)
        end

        it 'does not sync the changes' do
          expect(update_manager).not_to receive(:sync_changes!)
        end
      end

      context 'and run in force mode' do
        let(:options) { { force: true } }

        it 'prints a path of the added files' do
          expect($stdout).to receive(:puts).with(['path/to/file'])
        end

        it 'does not prompt the user to continue' do
          expect(PDK::CLI::Util).not_to receive(:prompt_for_yes)
        end

        it 'syncs the pending changes' do
          expect(update_manager).to receive(:sync_changes!)
        end
      end
    end
  end

  describe '#convert?' do
    subject { described_class.new.convert? }

    it { is_expected.to be_truthy }
  end

  describe '#template_uri' do
    subject { described_class.new(options).template_uri }

    let(:options) { {} }

    before(:each) do
      allow(PDK::Util).to receive(:package_install?).and_return(false)
      allow(PDK::Util::Git).to receive(:repo?).and_call_original
    end

    context 'when a template-url is provided in the options' do
      let(:options) { { :'template-url' => 'https://my/custom/template' } }

      before(:each) do
        allow(PDK::Util::Git).to receive(:repo?).with(options[:'template-url']).and_return(true)
      end

      it { is_expected.to eq(PDK::Util::TemplateURI.new("https://my/custom/template##{PDK::Util::TemplateURI.default_template_ref}")) }
    end

    context 'when no template-url is provided in the options' do
      before(:each) do
        allow(PDK::Util::Git).to receive(:repo?).with(PDK::Util::TemplateURI.default_template_uri.metadata_format).and_return(true)
      end

      let(:default_uri) { "#{PDK::Util::TemplateURI.default_template_uri}##{PDK::Util::TemplateURI.default_template_ref}" }

      it { is_expected.to eq(PDK::Util::TemplateURI.new(default_uri)) }
    end
  end

  describe '#update_metadata' do
    subject(:updated_metadata) do
      JSON.parse(described_class.new.update_metadata(metadata_path, template_metadata).to_json)
    end

    let(:metadata_path) { 'metadata.json' }
    let(:template_metadata) do
      {
        'template-url' => 'http://my.test/template.git',
        'template-ref' => 'v1.2.3',
      }
    end
    let(:new_metadata_file) { StringIO.new }

    before(:each) do
      allow(File).to receive(:open).with(any_args).and_call_original
      allow(PDK::Util).to receive(:package_install?).and_return(false)
    end

    context 'when the metadata file exists' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:exist?).with(metadata_path).and_return(true)
      end

      context 'and is a file' do
        before(:each) do
          allow(PDK::Util::Filesystem).to receive(:file?).with(metadata_path).and_return(true)
        end

        context 'and is readable' do
          before(:each) do
            allow(PDK::Util::Filesystem).to receive(:readable?).with(metadata_path).and_return(true)
            allow(PDK::Util::Filesystem).to receive(:read_file).with(metadata_path).and_return(existing_metadata)
          end

          let(:existing_metadata) do
            {
              'name'                    => 'testuser-testmodule',
              'requirements'            => [],
              'operatingsystem_support' => [],
              'license'                 => nil,
            }.to_json
          end

          it 'reads the existing metadata from the file' do
            expect(updated_metadata).to include('name' => 'testuser-testmodule')
          end

          it 'updates the metadata to include the missing keys from the module generation defaults' do
            expect(updated_metadata).to include('license' => 'Apache-2.0')
          end

          it 'updates the metadata with information about the template used to convert the module' do
            expect(updated_metadata).to include('template-url' => 'http://my.test/template.git', 'template-ref' => 'v1.2.3')
          end

          it 'updates an empty requirements array with a puppet requirement' do
            expect(updated_metadata).to include('requirements')
            expect(updated_metadata['requirements'].find { |req| req['name'] == 'puppet' }).not_to be_nil
          end

          it 'creates an empty dependencies array' do
            expect(updated_metadata).to include('dependencies' => [])
          end

          it 'does not modify an empty operatingsystem_support array' do
            expect(updated_metadata).to include('operatingsystem_support' => [])
          end

          context 'but contains invalid JSON' do
            let(:existing_metadata) { '' }

            it_behaves_like 'it interviews the user for the metadata'
          end
        end

        context 'and is not readable' do
          before(:each) do
            allow(PDK::Util::Filesystem).to receive(:readable?).with(metadata_path).and_return(false)
          end

          it 'exits with an error' do
            expect {
              described_class.new.update_metadata(metadata_path, template_metadata)
            }.to raise_error(PDK::CLI::ExitWithError, %r{exists but it is not readable})
          end
        end
      end

      context 'and is not a file' do
        before(:each) do
          allow(PDK::Util::Filesystem).to receive(:file?).with(metadata_path).and_return(false)
        end

        it 'exits with an error' do
          expect {
            described_class.new.update_metadata(metadata_path, template_metadata)
          }.to raise_error(PDK::CLI::ExitWithError, %r{exists but it is not a file})
        end
      end
    end

    context 'when the metadata file does not exist' do
      it_behaves_like 'it interviews the user for the metadata'
    end
  end

  describe '#add_tests?' do
    subject { described_class.new(options).add_tests? }

    context 'when add-tests => true' do
      let(:options) { { :'add-tests' => true } }

      it { is_expected.to be_truthy }
    end

    context 'when add-tests => false' do
      let(:options) { { :'add-tests' => false } }

      it { is_expected.to be_falsey }
    end
  end

  describe '#test_generators' do
    subject { described_class.new.test_generators }

    before(:each) do
      allow(PDK::Util::PuppetStrings).to receive(:all_objects).and_return(objects)
      allow(PDK::Util).to receive(:module_root).and_return(module_root)
      allow(PDK::Util).to receive(:module_metadata).and_return(metadata)
    end

    let(:metadata) { { 'name' => 'myuser-mymodule' } }
    let(:module_root) { File.join('path', 'to', 'module') }

    context 'when there are no objects' do
      let(:objects) { [] }

      it 'returns an empty array' do
        is_expected.to eq([])
      end
    end

    context 'when there are objects' do
      let(:objects) do
        [
          [
            PDK::Generate::PuppetClass, [
              { 'name' => 'foo' },
              { 'name' => 'bar' },
            ]
          ],
        ]
      end

      it 'returns an array of generators' do
        is_expected.to all(be_an_instance_of(PDK::Generate::PuppetClass))
      end

      it 'instantiates all the generators as spec_only' do
        is_expected.to all(have_attributes(spec_only?: true))
      end
    end
  end

  describe '#missing_tests?' do
    subject { instance.missing_tests? }

    before(:each) do
      allow(PDK::Util::PuppetStrings).to receive(:all_objects).and_return(objects)
      allow(PDK::Util).to receive(:module_root).and_return(module_root)
      allow(PDK::Util).to receive(:module_metadata).and_return(metadata)
    end

    let(:instance) { described_class.new }
    let(:metadata) { { 'name' => 'myuser-mymodule' } }
    let(:module_root) { File.join('path', 'to', 'module') }

    context 'when there are no objects' do
      let(:objects) { [] }

      it { is_expected.to be_falsey }
    end

    context 'when there are objects' do
      let(:objects) do
        [
          [
            PDK::Generate::PuppetClass, [
              { 'name' => 'mymodule::foo' },
            ]
          ],
        ]
      end

      context 'when the spec file exists' do
        before(:each) do
          instance.test_generators.each do |gen|
            allow(File).to receive(:exist?).with(gen.target_spec_path).and_return(true)
          end
        end

        it { is_expected.to be_falsey }
      end

      context 'when the spec file does not exist' do
        before(:each) do
          instance.test_generators.each do |gen|
            allow(File).to receive(:exist?).with(gen.target_spec_path).and_return(false)
          end
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#add_tests!' do
    let(:instance) { described_class.new }

    let(:generators) do
      [
        instance_double(PDK::Generate::PuppetClass),
      ]
    end

    before(:each) do
      allow(instance).to receive(:test_generators).and_return(generators)
    end

    context 'when the generators can run' do
      before(:each) do
        generators.each do |g|
          allow(g).to receive(:can_run?).and_return(true)
        end
      end

      it 'runs the generators' do
        expect(generators).to all(receive(:run))

        instance.add_tests!
      end
    end

    context 'when the generators can not run' do
      before(:each) do
        generators.each do |g|
          allow(g).to receive(:can_run?).and_return(false)
        end
      end

      it 'does not run the generators' do
        generators.each do |g|
          expect(g).not_to receive(:run)
        end

        instance.add_tests!
      end
    end
  end
end
