# frozen_string_literal: true

require 'spec_helper'

describe PDK::Validate::BaseValidator do
  context 'a class inheriting from BaseValidator' do
    subject(:validator) { Class.new(described_class) }

    it 'has an invoke method' do
      expect(validator.methods).to include(:invoke)
    end
  end

  describe '.parse_targets' do
    subject(:target_files) { described_class.parse_targets(targets: targets) }

    let(:module_root) { File.join('path', 'to', 'test', 'module') }
    let(:pattern) { '**/**.pp' }

    before(:each) do
      allow(described_class).to receive(:pattern).and_return(pattern)
      allow(PDK::Util).to receive(:module_root).and_return(module_root)
    end

    context 'when given no targets' do
      let(:targets) { [] }
      let(:glob_pattern) { File.join(module_root, described_class.pattern) }
      let(:globbed_files) do
        [
          File.join(module_root, 'manifests', 'init.pp'),
        ]
      end

      before(:each) do
        allow(File).to receive(:directory?).and_return(true)
        allow(Dir).to receive(:glob).with(glob_pattern).and_return(globbed_files)
        allow(File).to receive(:expand_path).with(module_root).and_return(module_root)
      end

      it 'returns the module root' do
        expect(target_files[0]).to eq(globbed_files)
      end
    end

    context 'when given specific targets' do
      let(:targets) { ['target1.pp', 'target2/'] }
      let(:glob_pattern) { File.join(module_root, described_class.pattern) }

      let(:globbed_target2) do
        [
          File.join(module_root, 'target2', 'target.pp'),
        ]
      end

      before(:each) do
        allow(Dir).to receive(:glob).with(glob_pattern).and_return(globbed_target2)
        allow(File).to receive(:directory?).with('target1.pp').and_return(false)
        allow(File).to receive(:directory?).with('target2/').and_return(true)
        allow(File).to receive(:file?).with('target1.pp').and_return(true)

        targets.map do |t|
          allow(File).to receive(:expand_path).with(t).and_return(File.join(module_root, t))
        end

        Array[described_class.pattern].flatten.map do |p|
          allow(File).to receive(:expand_path).with(p).and_return(File.join(module_root, p))
        end
      end

      it 'returns the targets' do
        expect(target_files[0]).to eq(globbed_target2)
        expect(target_files[1]).to eq(['target1.pp'])
        expect(target_files[2]).to be_empty
      end
    end

    context 'when given specific target with no matching files' do
      let(:targets) { ['target3/'] }

      let(:globbed_target2) do
        []
      end

      before(:each) do
        allow(Dir).to receive(:glob).with(File.join(module_root, described_class.pattern)).and_return(globbed_target2)
        allow(File).to receive(:directory?).with('target3/').and_return(true)
      end

      it 'returns the skipped' do
        expect(target_files[0]).to be_empty
        expect(target_files[1]).to eq(['target3/'].concat(globbed_target2))
        expect(target_files[2]).to be_empty
      end
    end

    context 'when given specific target that are not found' do
      let(:targets) { ['nonexistent.pp'] }

      before(:each) do
        allow(File).to receive(:directory?).with('nonexistent.pp').and_return(false)
        allow(File).to receive(:file?).with('nonexistent.pp').and_return(false)
      end

      it 'returns the invalid' do
        expect(target_files[0]).to be_empty
        expect(target_files[1]).to be_empty
        expect(target_files[2]).to eq(['nonexistent.pp'])
      end
    end

    context 'when there is no pattern' do
      let(:targets) { ['random'] }

      before(:each) do
        allow(described_class).to receive(:respond_to?).with(:pattern).and_return(false)
      end

      it 'returns the target as-is' do
        expect(target_files[0]).to eq(['random'])
        expect(target_files[1]).to be_empty
        expect(target_files[2]).to be_empty
      end
    end
  end
end
