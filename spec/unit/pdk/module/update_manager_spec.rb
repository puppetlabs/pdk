require 'spec_helper'
require 'pdk/module/update_manager'

describe PDK::Module::UpdateManager do
  subject(:update_manager) { described_class.new }

  let(:dummy_file) { File.join(Dir.pwd, 'test_file') }

  describe '#initialize' do
    it 'has no pending changes by default' do
      expect(update_manager).not_to be_changes
    end
  end

  describe '#add_file' do
    let(:content) { "some content\n" }

    before do
      update_manager.add_file(dummy_file, content)
    end

    it 'creates a pending change' do
      expect(update_manager).to be_changes
    end

    it 'creates a file added change' do
      expect(update_manager.changes).to include(added: [{ path: dummy_file, content: }])
    end

    it 'knows that the file will be changed' do
      expect(update_manager).to be_changed(dummy_file)
    end

    context 'when syncing the changes' do
      it 'writes the file to disk' do
        expect(PDK::Util::Filesystem).to receive(:write_file).with(dummy_file, content)

        update_manager.sync_changes!
      end

      context 'but if the file can not be written to' do
        before do
          allow(PDK::Util::Filesystem).to receive(:write_file).with(dummy_file, anything).and_raise(Errno::EACCES)
        end

        it 'exits with an error' do
          expect do
            update_manager.sync_changes!
          end.to raise_error(PDK::CLI::ExitWithError, /You do not have permission to write to '#{Regexp.escape(dummy_file)}'/)
        end
      end
    end
  end

  describe '#remove_file' do
    before do
      update_manager.remove_file(dummy_file)
    end

    context 'when the file does not exist on disk' do
      before do
        allow(PDK::Util::Filesystem).to receive(:exist?).with(dummy_file).and_return(false)
      end

      it 'does not create a pending change' do
        expect(update_manager).not_to be_changes
      end
    end

    context 'when the file exists on disk' do
      before do
        allow(PDK::Util::Filesystem).to receive(:exist?).with(dummy_file).and_return(true)
      end

      it 'creates a pending change' do
        expect(update_manager).to be_changes
      end

      it 'creates a file removed change' do
        expect(update_manager.changes).to include(removed: [dummy_file])
      end

      it 'knows that the file will be changed' do
        expect(update_manager).to be_changed(dummy_file)
      end

      context 'when syncing the changes' do
        context 'and the file exists' do
          before do
            allow(PDK::Util::Filesystem).to receive(:file?).with(dummy_file).and_return(true)
          end

          it 'removes the file' do
            expect(PDK::Util::Filesystem).to receive(:rm).with(dummy_file)

            update_manager.sync_changes!
          end

          context 'but it fails to remove the file' do
            before do
              allow(PDK::Util::Filesystem).to receive(:rm).with(dummy_file).and_raise(StandardError, 'an unknown error')
            end

            it 'exits with an error' do
              expect do
                update_manager.sync_changes!
              end.to raise_error(PDK::CLI::ExitWithError, /Unable to remove '#{Regexp.escape(dummy_file)}': an unknown error/)
            end
          end
        end

        context 'and the file does not exist' do
          before do
            allow(PDK::Util::Filesystem).to receive(:file?).with(dummy_file).and_return(false)
          end

          it 'does not attempt to remove the file' do
            expect(PDK::Util::Filesystem).not_to receive(:rm).with(dummy_file)

            update_manager.sync_changes!
          end
        end
      end
    end
  end

  describe '#modify_file' do
    let(:original_content) do
      <<-EOS.gsub(/^ {8}/, '')
        line 1
        line 2
        line 3
      EOS
    end

    let(:new_content) do
      <<-EOS.gsub(/^ {8}/, '')
        line 4
        line 2
        line 3
        line 1
      EOS
    end

    before do
      allow(PDK::Util::Filesystem).to receive(:readable?).with(dummy_file).and_return(true)
      allow(PDK::Util::Filesystem).to receive(:read_file).with(dummy_file).and_return(original_content)
      allow(PDK::Util::Filesystem).to receive(:stat).with(dummy_file).and_return(instance_double(File::Stat, mtime: Time.now - 60))
    end

    context 'when the file can not be opened for reading' do
      before do
        allow(PDK::Util::Filesystem).to receive(:readable?).with(dummy_file).and_return(false)
        update_manager.modify_file(dummy_file, new_content)
      end

      it 'exits with an error' do
        expect do
          update_manager.changes
        end.to raise_error(PDK::CLI::ExitWithError, /Unable to open '#{Regexp.escape(dummy_file)}' for reading/)
      end
    end

    context 'when the new file content differs from the original content' do
      let(:expected_diff) do
        <<-EOS.chomp.gsub(/^ {10}/, '')
          @@ -1,3 +1,4 @@
          -line 1
          +line 4
           line 2
           line 3
          +line 1
        EOS
      end

      before do
        update_manager.modify_file(dummy_file, new_content)
      end

      it 'creates a pending change' do
        expect(update_manager).to be_changes
      end

      it 'creates a file modified change' do
        expect(update_manager.changes).to include(modified: { dummy_file => anything })
      end

      it 'creates a diff of the changes' do
        diff_lines = update_manager.changes[:modified][dummy_file].split("\n")
        expect(diff_lines[0]).to match(/\A--- #{Regexp.escape(dummy_file)}.+/)
        expect(diff_lines[1]).to match(/\A\+\+\+ #{Regexp.escape(dummy_file)}\.pdknew.+/)
        expect(diff_lines[2..].join("\n")).to eq(expected_diff)
      end

      it 'knows that the file will be changed' do
        expect(update_manager).to be_changed(dummy_file)
      end

      context 'when syncing the changes' do
        it 'writes the modified file to disk' do
          expect(PDK::Util::Filesystem).to receive(:write_file).with(dummy_file, new_content)

          update_manager.sync_changes!
        end

        context 'but if the file can not be written to' do
          before do
            allow(PDK::Util::Filesystem).to receive(:write_file).with(dummy_file, anything).and_raise(Errno::EACCES)
          end

          it 'exits with an error' do
            expect do
              update_manager.sync_changes!
            end.to raise_error(PDK::CLI::ExitWithError, /You do not have permission to write to '#{Regexp.escape(dummy_file)}'/)
          end
        end
      end
    end

    context 'when the new file content matches the original content' do
      before do
        update_manager.modify_file(dummy_file, original_content)
      end

      it 'does not create a pending change' do
        expect(update_manager).not_to be_changes
      end

      it 'does not create a file modified change' do
        expect(update_manager.changes).to include(modified: {})
      end

      it 'knows that the file will not be changed' do
        expect(update_manager).not_to be_changed(dummy_file)
      end

      context 'when syncing the changes' do
        it 'does not modify the file' do
          expect(PDK::Util::Filesystem).not_to receive(:write_file).with(dummy_file, anything)

          update_manager.sync_changes!
        end
      end
    end
  end

  describe '#make_file_executable' do
    before do
      update_manager.make_file_executable(dummy_file)
    end

    it 'creates a pending change' do
      expect(update_manager).to be_changes
    end

    it 'creates a file made executable change' do
      expect(update_manager.changes).to include('made executable': [dummy_file])
    end

    it 'knows that the file will be changed' do
      expect(update_manager).to be_changed(dummy_file)
    end

    context 'when syncing the changes' do
      it 'makes the file executable' do
        expect(PDK::Util::Filesystem).to receive(:make_executable).with(dummy_file)

        update_manager.sync_changes!
      end

      context 'but if the file can not be written to' do
        before do
          allow(PDK::Util::Filesystem).to receive(:make_executable).with(dummy_file).and_raise(Errno::EACCES)
        end

        it 'exits with an error' do
          expect do
            update_manager.sync_changes!
          end.to raise_error(PDK::CLI::ExitWithError, /You do not have permission to make '#{Regexp.escape(dummy_file)}' executable/)
        end
      end
    end
  end

  describe '#clear!' do
    before do
      update_manager.add_file(dummy_file, 'content')
      update_manager.modify_file(dummy_file, 'content')
      update_manager.remove_file(dummy_file)
      allow(update_manager).to receive(:calculate_diffs).and_return(nil) # rubocop:disable RSpec/SubjectStub This is fine.
    end

    it 'clears all pending changes' do
      expect(update_manager.changes?).to be true
      update_manager.clear!
      expect(update_manager.changes?).to be false
    end
  end
end
