require 'spec_helper'
require 'pdk/validate/base_validator'

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
      allow(PDK::Util).to receive(:canonical_path).and_wrap_original do |_m, *args|
        args[0]
      end
    end

    context 'when given no targets' do
      let(:targets) { [] }
      let(:glob_pattern) { File.join(module_root, described_class.pattern) }
      let(:files) { [File.join('manifests', 'init.pp')] }
      let(:globbed_files) { files.map { |file| File.join(module_root, file) } }

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).and_return(true)
        allow(PDK::Util::Filesystem).to receive(:glob).with(glob_pattern, anything).and_return(globbed_files)
        allow(PDK::Util::Filesystem).to receive(:expand_path).with(module_root).and_return(module_root)
      end

      it 'returns the module root' do
        expect(target_files[0]).to eq(files)
      end
    end

    context 'when the globbed files include files matching the default ignore list' do
      let(:targets) { [] }
      let(:glob_pattern) { File.join(module_root, described_class.pattern) }
      let(:files) { [File.join('manifests', 'init.pp')] }
      let(:fixture_file) { File.join(module_root, 'spec', 'fixtures', 'modules', 'test', 'manifests', 'init.pp') }
      let(:pkg_file) { File.join(module_root, 'pkg', 'my-module-0.0.1', 'manifests', 'init.pp') }
      let(:globbed_files) do
        [
          File.join(module_root, 'manifests', 'init.pp'),
          fixture_file,
          pkg_file,
        ]
      end

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).and_return(true)
        allow(PDK::Util::Filesystem).to receive(:glob).with(glob_pattern, anything).and_return(globbed_files)
        allow(PDK::Util::Filesystem).to receive(:expand_path).with(module_root).and_return(module_root)
      end

      it 'does not return the files under spec/fixtures/' do
        expect(target_files[0]).not_to include(a_string_including('spec/fixtures'))
      end

      it 'does not return the files under pkg/' do
        expect(target_files[0]).not_to include(a_string_including('pkg/'))
      end
    end

    context 'when given specific targets' do
      let(:targets) { ['target1.pp', 'target2/'] }
      let(:glob_pattern) { File.join(module_root, described_class.pattern) }
      let(:targets2) { [File.join('target2', 'target.pp')] }
      let(:globbed_target2) { targets2.map { |target| File.join(module_root, target) } }

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:glob).with(glob_pattern, anything).and_return(globbed_target2)
        allow(PDK::Util::Filesystem).to receive(:directory?).with('target1.pp').and_return(false)
        allow(PDK::Util::Filesystem).to receive(:directory?).with('target2/').and_return(true)
        allow(PDK::Util::Filesystem).to receive(:file?).with('target1.pp').and_return(true)

        targets.map do |t|
          allow(PDK::Util::Filesystem).to receive(:expand_path).with(t).and_return(File.join(module_root, t))
        end

        Array[described_class.pattern].flatten.map do |p|
          allow(PDK::Util::Filesystem).to receive(:expand_path).with(p).and_return(File.join(module_root, p))
        end
      end

      it 'returns the targets' do
        expect(target_files[0]).to eq(targets2)
        expect(target_files[1]).to eq(['target1.pp'])
        expect(target_files[2]).to be_empty
      end
    end

    context 'when given specific targets which are not in the glob_pattern' do
      let(:pattern) { ['metadata.json', 'tasks/*.json'] }
      let(:targets) { ['target1.pp', 'target2/'] }

      before(:each) do
        # The glob simulates a module with a metadata.json
        allow(PDK::Util::Filesystem).to receive(:glob).with(File.join(module_root, 'metadata.json'), anything).and_return([File.join(module_root, 'metadata.json')])
        # The glob simulates a module without any tasks
        allow(PDK::Util::Filesystem).to receive(:glob).with(File.join(module_root, 'tasks/*.json'), anything).and_return([])
        allow(PDK::Util::Filesystem).to receive(:directory?).with('target1.pp').and_return(false)
        allow(PDK::Util::Filesystem).to receive(:directory?).with('target2/').and_return(true)
        allow(PDK::Util::Filesystem).to receive(:file?).with('target1.pp').and_return(true)

        targets.map do |t|
          allow(PDK::Util::Filesystem).to receive(:expand_path).with(t).and_return(File.join(module_root, t))
        end

        Array[described_class.pattern].flatten.map do |p|
          allow(PDK::Util::Filesystem).to receive(:expand_path).with(p).and_return(File.join(module_root, p))
        end
      end

      it 'returns all targets as skipped' do
        expect(target_files[0]).to be_empty
        expect(target_files[1]).to eq(targets)
        expect(target_files[2]).to be_empty
      end
    end

    context 'when given specific targets which are case insensitive on a case insensitive file system' do
      let(:targets) { ['target2/'] }
      let(:glob_pattern) { File.join(module_root, described_class.pattern) }
      let(:real_targets) { [File.join('target2', 'target.pp')] }
      let(:globbed_targets) { real_targets.map { |target| File.join(module_root, target) } }

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:glob).with(glob_pattern, anything).and_return(globbed_targets)
        allow(PDK::Util::Filesystem).to receive(:directory?).and_return(true)
        targets.map do |t|
          allow(PDK::Util::Filesystem).to receive(:expand_path).with(t).and_return(File.join(module_root, t))
          # PDK::Util.canonical_path will then convert the case-insensitive paths
          # back to their "real" on-disk names. In this case, lowercase
          expect(PDK::Util).to receive(:canonical_path).with(t.upcase).and_return(t)
        end

        Array[described_class.pattern].flatten.map do |p|
          allow(PDK::Util::Filesystem).to receive(:expand_path).with(p).and_return(File.join(module_root, p))
        end
      end

      it 'returns the targets' do
        # Simulate passing in case insensitive targets
        targets.map! { |target| target.upcase }

        expect(target_files[0]).to eq(real_targets)
        expect(target_files[1]).to be_empty
        expect(target_files[2]).to be_empty
      end
    end

    context 'when given specific target with no matching files' do
      let(:targets) { ['target3/'] }

      let(:globbed_target2) do
        []
      end

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:glob).with(File.join(module_root, described_class.pattern), anything).and_return(globbed_target2)
        allow(PDK::Util::Filesystem).to receive(:directory?).with('target3/').and_return(true)
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
        allow(PDK::Util::Filesystem).to receive(:directory?).with('nonexistent.pp').and_return(false)
        allow(PDK::Util::Filesystem).to receive(:file?).with('nonexistent.pp').and_return(false)
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

    context 'when specifying an ignore pattern' do
      before(:each) do
        allow(described_class).to receive(:pattern_ignore).and_return('/plans/**/**.pp')

        allow(PDK::Util::Filesystem).to receive(:directory?).and_return(true)
        allow(PDK::Util::Filesystem).to receive(:glob).with(glob_pattern, anything).and_return(globbed_files)
        allow(PDK::Util::Filesystem).to receive(:expand_path).with(module_root).and_return(module_root)
      end

      let(:targets) { [] }
      let(:glob_pattern) { File.join(module_root, described_class.pattern) }
      let(:files) do
        [
          File.join('manifests', 'init.pp'),
          File.join('plans', 'foo.pp'),
          File.join('plans', 'nested', 'thing.pp'),
        ]
      end
      let(:globbed_files) { files.map { |file| File.join(module_root, file) } }

      it 'does not match the ignored files' do
        expect(target_files[0].count).to eq(1)
        expect(target_files[0]).to eq([File.join('manifests', 'init.pp')])
      end
    end
  end
end
