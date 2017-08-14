RSpec.shared_examples_for 'it accepts .pp targets' do
  describe '.parse_targets' do
    subject(:parsed_targets) { described_class.parse_targets(targets: targets) }

    let(:globbed_files) { [] }
    let(:glob_pattern) { File.join(module_root, described_class.pattern) }

    before(:each) do
      allow(Dir).to receive(:glob).with(glob_pattern).and_return(globbed_files)
    end

    context 'when given no targets' do
      let(:targets) { [] }

      context 'and the module contains .pp files' do
        let(:globbed_files) do
          [
            File.join(module_root, 'manifests', 'init.pp'),
            File.join(module_root, 'manifests', 'params.pp'),
          ]
        end

        it 'returns the paths to all the .pp files in the module' do
          expect(parsed_targets.first).to eq(globbed_files)
        end
      end

      context 'and the module contains no .pp files' do
        it 'returns no targets' do
          expect(parsed_targets.first).to eq([])
        end
      end
    end

    context 'when given specific target files' do
      let(:targets) { ['manifest.pp', 'another.pp'] }

      before(:each) do
        targets.each do |target|
          allow(File).to receive(:directory?).with(target).and_return(false)
          allow(File).to receive(:file?).with(target).and_return(true)
        end
      end

      it 'returns the targets' do
        expect(parsed_targets.first).to eq(targets)
      end
    end

    context 'when given a specific target directory' do
      let(:targets) { [File.join('path', 'to', 'target', 'directory')] }
      let(:glob_pattern) { File.join(targets.first, described_class.pattern) }

      before(:each) do
        allow(File).to receive(:directory?).with(targets.first).and_return(true)
      end

      context 'and the directory contains .pp files' do
        let(:globbed_files) { [File.join(targets.first, 'test.pp')] }

        it 'returns the paths to the .pp files in the directory' do
          expect(parsed_targets.first).to eq(globbed_files)
        end
      end

      context 'and the directory contains no .pp files' do
        it 'returns no targets' do
          expect(parsed_targets.first).to eq([])
        end
      end
    end
  end
end
