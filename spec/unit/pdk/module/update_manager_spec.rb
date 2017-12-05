require 'spec_helper'
require 'pdk/module/update_manager'

describe PDK::Module::UpdateManager do
  subject(:update_manager) { described_class.new }

  let(:dummy_file) { File.join(Dir.pwd, 'test_file') }

  describe '#initialize' do
    it 'has no pending changes by default' do
      expect(update_manager.changes?).to be_falsey
    end
  end

  describe '#add_file' do
    let(:content) { "some content\n" }

    before(:each) do
      update_manager.add_file(dummy_file, content)
    end

    it 'creates a pending change' do
      expect(update_manager.changes?).to be_truthy
    end

    it 'creates a file added change' do
      expect(update_manager.changes).to include(added: [{ path: dummy_file, content: content }])
    end

    it 'knows that the file will be changed' do
      expect(update_manager.changed?(dummy_file)).to be_truthy
    end

    context 'when syncing the changes' do
      let(:dummy_file_io) { StringIO.new }

      before(:each) do
        allow(File).to receive(:open).with(any_args).and_call_original
        allow(File).to receive(:open).with(dummy_file, 'w').and_yield(dummy_file_io)
        update_manager.sync_changes!
        dummy_file_io.rewind
      end

      it 'writes the file to disk' do
        expect(dummy_file_io.read).to eq(content)
      end

      context 'but if the file can not be written to' do
        before(:each) do
          allow(File).to receive(:open).with(dummy_file, 'w').and_raise(Errno::EACCES)
        end

        it 'exits with an error' do
          expect {
            update_manager.sync_changes!
          }.to raise_error(PDK::CLI::ExitWithError, %r{You do not have permission to write to '#{Regexp.escape(dummy_file)}'})
        end
      end
    end
  end

  describe '#remove_file' do
    before(:each) do
      update_manager.remove_file(dummy_file)
    end

    it 'creates a pending change' do
      expect(update_manager.changes?).to be_truthy
    end

    it 'creates a file removed change' do
      expect(update_manager.changes).to include(removed: [dummy_file])
    end

    it 'knows that the file will be changed' do
      expect(update_manager.changed?(dummy_file)).to be_truthy
    end

    context 'when syncing the changes' do
      context 'and the file exists' do
        before(:each) do
          allow(File).to receive(:file?).with(dummy_file).and_return(true)
        end

        it 'removes the file' do
          expect(FileUtils).to receive(:rm).with(dummy_file)

          update_manager.sync_changes!
        end

        context 'but it fails to remove the file' do
          before(:each) do
            allow(FileUtils).to receive(:rm).with(dummy_file).and_raise(StandardError, 'an unknown error')
          end

          it 'exits with an error' do
            expect {
              update_manager.sync_changes!
            }.to raise_error(PDK::CLI::ExitWithError, %r{Unable to remove '#{Regexp.escape(dummy_file)}': an unknown error})
          end
        end
      end

      context 'and the file does not exist' do
        before(:each) do
          allow(File).to receive(:file?).with(dummy_file).and_return(false)
        end

        it 'does not attempt to remove the file' do
          expect(FileUtils).not_to receive(:rm).with(dummy_file)

          update_manager.sync_changes!
        end
      end
    end
  end

  describe '#modify_file' do
    let(:original_content) do
      <<-EOS.gsub(%r{^ {8}}, '')
        line 1
        line 2
        line 3
      EOS
    end

    let(:new_content) do
      <<-EOS.gsub(%r{^ {8}}, '')
        line 4
        line 2
        line 3
        line 1
      EOS
    end

    before(:each) do
      allow(File).to receive(:readable?).with(dummy_file).and_return(true)
      allow(File).to receive(:read).with(dummy_file).and_return(original_content)
      allow(File).to receive(:stat).with(dummy_file).and_return(instance_double(File::Stat, mtime: Time.now - 60))
    end

    context 'when the file can not be opened for reading' do
      before(:each) do
        allow(File).to receive(:readable?).with(dummy_file).and_return(false)
        update_manager.modify_file(dummy_file, new_content)
      end

      it 'exits with an error' do
        expect {
          update_manager.changes
        }.to raise_error(PDK::CLI::ExitWithError, %r{Unable to open '#{Regexp.escape(dummy_file)}' for reading})
      end
    end

    context 'when the new file content differs from the original content' do
      let(:expected_diff) do
        <<-EOS.chomp.gsub(%r{^ {10}}, '')
          @@ -1,4 +1,5 @@
          -line 1
          +line 4
           line 2
           line 3
          +line 1
        EOS
      end

      before(:each) do
        update_manager.modify_file(dummy_file, new_content)
      end

      it 'creates a pending change' do
        expect(update_manager.changes?).to be_truthy
      end

      it 'creates a file modified change' do
        expect(update_manager.changes).to include(modified: { dummy_file => anything })
      end

      it 'creates a diff of the changes' do
        diff_lines = update_manager.changes[:modified][dummy_file].split("\n")
        expect(diff_lines[0]).to match(%r{\A--- #{Regexp.escape(dummy_file)}.+})
        expect(diff_lines[1]).to match(%r{\A\+\+\+ #{Regexp.escape(dummy_file)}\.pdknew.+})
        expect(diff_lines[2..-1].join("\n")).to eq(expected_diff)
      end

      it 'knows that the file will be changed' do
        expect(update_manager.changed?(dummy_file)).to be_truthy
      end

      context 'when syncing the changes' do
        let(:dummy_file_io) { StringIO.new }

        before(:each) do
          allow(File).to receive(:open).with(any_args).and_call_original
          allow(File).to receive(:open).with(dummy_file, 'w').and_yield(dummy_file_io)
          update_manager.sync_changes!
          dummy_file_io.rewind
        end

        it 'writes the modified file to disk' do
          expect(dummy_file_io.read).to eq(new_content)
        end

        context 'but if the file can not be written to' do
          before(:each) do
            allow(File).to receive(:open).with(dummy_file, 'w').and_raise(Errno::EACCES)
          end

          it 'exits with an error' do
            expect {
              update_manager.sync_changes!
            }.to raise_error(PDK::CLI::ExitWithError, %r{You do not have permission to write to '#{Regexp.escape(dummy_file)}'})
          end
        end
      end
    end

    context 'when the new file content matches the original content' do
      before(:each) do
        update_manager.modify_file(dummy_file, original_content)
      end

      it 'does not create a pending change' do
        expect(update_manager.changes?).to be_falsey
      end

      it 'does not create a file modified change' do
        expect(update_manager.changes).to include(modified: {})
      end

      it 'knows that the file will not be changed' do
        expect(update_manager.changed?(dummy_file)).to be_falsey
      end

      context 'when syncing the changes' do
        it 'does not modify the file' do
          expect(File).not_to receive(:open).with(dummy_file, 'w')
          update_manager.sync_changes!
        end
      end
    end
  end
end
