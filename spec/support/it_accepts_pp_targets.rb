RSpec.shared_examples_for 'it accepts .pp targets' do
  describe '.parse_targets' do
    subject(:parsed_targets) { described_class.parse_targets(targets: targets) }

    let(:globbed_files) { [] }
    let(:glob_pattern) { File.join(module_root, described_class.pattern) }

    before(:each) do
      allow(Dir).to receive(:glob).with(glob_pattern).and_return(globbed_files)
      allow(File).to receive(:expand_path).with(module_root).and_return(module_root)
    end

    context 'when given no targets' do
      let(:targets) { [] }

      context 'and the module contains .pp files' do
        let(:files) do
          [
            File.join('manifests', 'init.pp'),
            File.join('manifests', 'params.pp'),
          ]
        end

        let(:globbed_files) { files.map { |file| File.join(module_root, file) } }

        it 'returns the paths to all the .pp files in the module' do
          expect(parsed_targets.first).to eq(files)
        end
      end

      context 'and the module contains no .pp files' do
        it 'returns no targets' do
          expect(parsed_targets.first).to eq([])
        end
      end
    end

    context 'when given specific target files' do
      let(:targets) { ['manifests/manifest.pp', 'manifests/foo/another.pp'] }

      before(:each) do
        allow(File).to receive(:expand_path).with(described_class.pattern).and_return(File.join(module_root, described_class.pattern))
        targets.each do |target|
          allow(File).to receive(:directory?).with(target).and_return(false)
          allow(File).to receive(:file?).with(target).and_return(true)
          allow(File).to receive(:expand_path).with(target).and_return(File.join(module_root, target))
        end
      end

      it 'returns the targets' do
        expect(parsed_targets.first).to eq(targets)
      end
    end
  end
end
