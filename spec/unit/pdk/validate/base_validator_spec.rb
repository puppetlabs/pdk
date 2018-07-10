require 'spec_helper'

describe PDK::Validate::BaseValidator do
  context 'a class inheriting from BaseValidator' do
    subject(:validator) { Class.new(described_class) }

    it 'has an invoke method' do
      expect(validator.methods).to include(:invoke)
    end
  end

  describe '.invoke' do
    before(:each) do
      allow(described_class).to receive(:parse_targets).and_return([(1..1001).map(&:to_s), [], []])
      allow(described_class).to receive(:cmd).and_return('dummy_cmd')
      allow(PDK::Util::Bundler).to receive(:ensure_binstubs!).with('dummy_cmd')
      allow(described_class).to receive(:parse_output)
    end

    let(:dummy_exec) do
      instance_double(PDK::CLI::Exec::Command, :context= => nil, :execute! => { exit_code: 0 })
    end

    after(:each) do
      described_class.invoke(instance_double(PDK::Report))
    end

    context 'when validating less than 1000 targets' do
      before(:each) do
        allow(described_class).to receive(:parse_targets).and_return([(1..999).map(&:to_s), [], []])
      end

      it 'executes the validator once' do
        expect(PDK::CLI::Exec::Command).to receive(:new).and_return(dummy_exec).once
      end

      context 'if the output fails to parse' do
        before(:each) do
          allow(described_class).to receive(:parse_output)
            .with(any_args).and_raise(PDK::Validate::ParseOutputError, 'test')
          allow(PDK::CLI::Exec::Command).to receive(:new).and_return(dummy_exec)
        end

        it 'prints the validator output to STDERR' do
          expect($stderr).to receive(:puts).with('test')
        end
      end
    end

    context 'when validating more than 1000 targets' do
      before(:each) do
        allow(described_class).to receive(:parse_targets).and_return([(1..1001).map(&:to_s), [], []])
      end

      it 'executes the validator for each block of up to 1000 targets' do
        expect(PDK::CLI::Exec::Command).to receive(:new).and_return(dummy_exec).twice
      end

      context 'if the output fails to parse' do
        before(:each) do
          allow(described_class).to receive(:parse_output)
            .with(any_args).and_raise(PDK::Validate::ParseOutputError, 'test').twice
          allow(PDK::CLI::Exec::Command).to receive(:new).and_return(dummy_exec).twice
        end

        it 'prints the validator output to STDERR' do
          expect($stderr).to receive(:puts).with('test').twice
        end
      end
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

    context 'when the globbed files include spec/fixtures files' do
      let(:targets) { [] }
      let(:glob_pattern) { File.join(module_root, described_class.pattern) }
      let(:fixture_file) { File.join(module_root, 'spec', 'fixtures', 'test', 'manifests', 'init.pp') }
      let(:globbed_files) do
        [
          File.join(module_root, 'manifests', 'init.pp'),
          fixture_file,
        ]
      end

      before(:each) do
        allow(File).to receive(:directory?).and_return(true)
        allow(Dir).to receive(:glob).with(glob_pattern).and_return(globbed_files)
        allow(File).to receive(:expand_path).with(module_root).and_return(module_root)
      end

      it 'does not return the files under spec/fixtures' do
        expect(target_files[0]).not_to include(fixture_file)
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
