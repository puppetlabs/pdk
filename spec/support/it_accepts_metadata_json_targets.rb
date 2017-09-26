RSpec.shared_examples_for 'it accepts metadata.json targets' do
  describe '.parse_targets' do
    subject(:parsed_targets) { described_class.parse_targets(targets: targets) }

    let(:module_metadata_json) { File.join(module_root, 'metadata.json') }
    let(:globbed_files) { [] }
    let(:glob_pattern) do
      Array(described_class.pattern).flatten.map { |pattern| File.join(module_root, pattern) }
    end

    before(:each) do
      glob_pattern.each do |pattern|
        allow(Dir).to receive(:glob).with(pattern).and_return(globbed_files)
      end
    end

    context 'when given no targets' do
      let(:targets) { [] }

      context 'and the module contains a metadata.json file' do
        before(:each) do
          allow(Dir).to receive(:glob).with(module_metadata_json).and_return([module_metadata_json])
          allow(File).to receive(:expand_path).with(module_root).and_return(module_root)
        end

        it 'returns the path to metadata.json in the module' do
          expect(parsed_targets.first).to eq([module_metadata_json])
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
  end
end
