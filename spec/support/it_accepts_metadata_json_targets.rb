RSpec.shared_examples_for 'it accepts metadata.json targets' do
  describe '.parse_targets' do
    subject(:parsed_targets) { described_class.parse_targets(targets: targets) }

    let(:module_metadata_json) { File.join(module_root, 'metadata.json') }
    let(:glob_pattern) { File.join(module_root, described_class.pattern) }
    let(:globbed_files) { [] }

    before(:each) do
      allow(Dir).to receive(:glob).with(glob_pattern).and_return(globbed_files)
    end

    context 'when given no targets' do
      let(:targets) { [] }

      context 'and the module contains a metadata.json file' do
        let(:globbed_files) { [module_metadata_json] }

        it 'returns the path to metadata.json in the module' do
          expect(parsed_targets.first).to eq(globbed_files)
        end
      end

      context 'and the module does not contain a metadata.json file' do
        it 'returns no targets' do
          expect(parsed_targets.first).to eq([])
        end
      end
    end

    context 'when given a target that will not match the validator\s pattern' do
      let(:targets) { ['target1', 'target2.json'] }

      before(:each) do
        targets.each do |target|
          allow(File).to receive(:directory?).with(target).and_return(false)
          allow(File).to receive(:file?).with(target).and_return(true)
        end
      end

      it 'skips the targets' do
        expect(parsed_targets[0]).to eq([])
        expect(parsed_targets[1]).to eq(['target1', 'target2.json'])
        expect(parsed_targets[2]).to eq([])
      end
    end

    context 'when given a specific target directory' do
      let(:targets) { [File.join('path', 'to', 'target', 'directory')] }
      let(:glob_pattern) { File.join(targets.first, described_class.pattern) }

      before(:each) do
        targets.each do |target|
          allow(File).to receive(:directory?).with(target).and_return(true)
        end
      end

      context 'and the directory contains a metadata.json file' do
        let(:globbed_files) { [File.join(targets.first, 'metadata.json')] }

        it 'returns the path to the metadata.json file in the target directory' do
          expect(parsed_targets.first).to eq(globbed_files)
        end
      end

      context 'and the directory does not contain a metadata.json file' do
        it 'returns no targets' do
          expect(parsed_targets.first).to eq([])
        end
      end
    end
  end
end
