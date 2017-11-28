require 'spec_helper'
require 'pdk/module/convert'

describe PDK::Module::Convert do
  shared_examples_for 'it interviews the user for the metadata' do
    it 'interviews the user for the metadata' do
      expect(PDK::Generate::Module).to receive(:prepare_metadata).and_return(PDK::Module::Metadata.new)
      described_class.update_metadata(metadata_path, template_metadata)
    end

    it 'updates the metadata with information about the template used to convert the module' do
      allow(PDK::Generate::Module).to receive(:prepare_metadata).and_return(PDK::Module::Metadata.new)
      expect(updated_metadata).to include('template-url' => 'http://my.test/template.git', 'template-ref' => 'v1.2.3')
    end
  end

  describe '.invoke' do
    let(:options) { {} }
    let(:update_manager) { instance_double(PDK::Module::UpdateManager, sync_changes!: true) }
    let(:template_dir) { instance_double(PDK::Module::TemplateDir, metadata: {}) }
    let(:template_files) { { path: 'a/path/to/file', content: 'file contents' } }
    let(:added_files) { [] }
    let(:removed_files) { [] }
    let(:modified_files) { {} }

    before(:each) do
      changes = { added: added_files, removed: removed_files, modified: modified_files }

      allow(PDK::Module::UpdateManager).to receive(:new).and_return(update_manager)
      allow(described_class).to receive(:update_metadata).with(anything, anything).and_return('')
      allow(PDK::Module::TemplateDir).to receive(:new).with(anything, anything, anything).and_yield(template_dir)
      allow(template_dir).to receive(:render).and_yield(template_files[:path], template_files[:content])
      allow(update_manager).to receive(:changes).and_return(changes)
    end

    after(:each) do
      described_class.invoke(options)
    end

    context 'when there are no changes to apply' do
      before(:each) do
        allow(File).to receive(:exist?).with('a/path/to/file').and_return(true)
        allow(update_manager).to receive(:changes?).and_return(false)
        allow(template_dir).to receive(:render)
        allow(PDK::Module::TemplateDir).to receive(:files_in_template).and_return({})

        expect(update_manager).to receive(:modify_file).with('metadata.json', anything)
      end

      it 'returns without syncing the changes' do
        expect(update_manager).not_to receive(:sync_changes!)
      end
    end

    context 'when there are changes to apply' do
      before(:each) do
        allow(File).to receive(:exist?).with('a/path/to/file').and_return(true)
        allow(update_manager).to receive(:modify_file).with(any_args)
        allow(update_manager).to receive(:changes?).and_return(true)
        allow($stdout).to receive(:puts).with('a diff')

        expect(update_manager).to receive(:modify_file).with('metadata.json', anything)
        expect(update_manager).to receive(:modify_file).with(template_files[:path], template_files[:content])
      end

      let(:modified_files) do
        {
          'some/file' => 'a diff',
        }
      end

      context 'and run normally' do
        it 'prints a diff of the changed files' do
          allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(false)
          expect($stdout).to receive(:puts).with('a diff')
        end

        it 'prompts the user to continue' do
          expect(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(false)
        end

        context 'if the user chooses to continue' do
          before(:each) do
            allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(true)
          end

          it 'syncs the pending changes' do
            expect(update_manager).to receive(:sync_changes!)
          end
        end

        context 'if the user chooses not to continue' do
          before(:each) do
            allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(false)
          end

          it 'does not sync the changes' do
            expect(update_manager).not_to receive(:sync_changes!)
          end
        end
      end

      context 'and run in noop mode' do
        let(:options) { { noop: true } }

        it 'prints a diff of the changed files' do
          expect($stdout).to receive(:puts).with('a diff')
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

        it 'prints a diff of the changed files' do
          expect($stdout).to receive(:puts).with('a diff')
        end

        it 'does not prompt the user to continue' do
          expect(PDK::CLI::Util).not_to receive(:prompt_for_yes)
        end

        it 'syncs the pending changes' do
          expect(update_manager).to receive(:sync_changes!)
        end
      end
    end

    context 'when there are files to add' do
      let(:added_files) do
        [{
          path:   'path/to/file',
          content: 'file contents',
        }]
      end

      before(:each) do
        allow(File).to receive(:exist?).with('a/path/to/file').and_return(false)
        allow(update_manager).to receive(:changes?).and_return(true)
        allow($stdout).to receive(:puts).with('path/to/file')

        expect(update_manager).to receive(:modify_file).with('metadata.json', anything)
        expect(update_manager).to receive(:add_file).with(template_files[:path], template_files[:content])
      end

      context 'and run normally' do
        it 'prints a path of the added files' do
          allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(false)
          expect($stdout).to receive(:puts).with('path/to/file')
        end

        it 'prompts the user to continue' do
          expect(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(false)
        end

        context 'if the user chooses to continue' do
          before(:each) do
            allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(true)
          end

          it 'syncs the pending changes' do
            expect(update_manager).to receive(:sync_changes!)
          end
        end

        context 'if the user chooses not to continue' do
          before(:each) do
            allow(PDK::CLI::Util).to receive(:prompt_for_yes).with(anything).and_return(false)
          end

          it 'does not sync the changes' do
            expect(update_manager).not_to receive(:sync_changes!)
          end
        end
      end

      context 'and run in noop mode' do
        let(:options) { { noop: true } }

        it 'prints a path of the added files' do
          expect($stdout).to receive(:puts).with('path/to/file')
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
          expect($stdout).to receive(:puts).with('path/to/file')
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

  describe '.update_metadata' do
    subject(:updated_metadata) do
      JSON.parse(described_class.update_metadata(metadata_path, template_metadata))
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
    end

    context 'when the metadata file exists' do
      before(:each) do
        allow(File).to receive(:exist?).with(metadata_path).and_return(true)
      end

      context 'and is a file' do
        before(:each) do
          allow(File).to receive(:file?).with(metadata_path).and_return(true)
        end

        context 'and is readable' do
          before(:each) do
            allow(File).to receive(:readable?).with(metadata_path).and_return(true)
            allow(File).to receive(:read).with(metadata_path).and_return(existing_metadata)
          end

          let(:existing_metadata) do
            {
              'name' => 'testuser-testmodule',
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

          context 'but contains invalid JSON' do
            let(:existing_metadata) { '' }

            it_behaves_like 'it interviews the user for the metadata'
          end
        end

        context 'and is not readable' do
          before(:each) do
            allow(File).to receive(:readable?).with(metadata_path).and_return(false)
          end

          it 'exits with an error' do
            expect {
              described_class.update_metadata(metadata_path, template_metadata)
            }.to raise_error(PDK::CLI::ExitWithError, %r{exists but it is not readable})
          end
        end
      end

      context 'and is not a file' do
        before(:each) do
          allow(File).to receive(:file?).with(metadata_path).and_return(false)
        end

        it 'exits with an error' do
          expect {
            described_class.update_metadata(metadata_path, template_metadata)
          }.to raise_error(PDK::CLI::ExitWithError, %r{exists but it is not a file})
        end
      end
    end

    context 'when the metadata file does not exist' do
      it_behaves_like 'it interviews the user for the metadata'
    end
  end
end
