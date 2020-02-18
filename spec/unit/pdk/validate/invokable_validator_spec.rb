require 'spec_helper'
require 'pdk/validate/invokable_validator'

describe PDK::Validate::InvokableValidator do
  let(:validator) { described_class.new(validator_context, validator_options) }
  let(:validator_options) { {} }
  let(:context_root) { File.join('path', 'to', 'test', 'module') }
  let(:validator_context) { PDK::Context::Module.new(context_root, context_root) }

  it 'inherits from PDK::Validate::Validator' do
    expect(validator).to be_a(PDK::Validate::Validator)
  end

  it 'has an invoke_style of :once' do
    expect(validator.invoke_style).to eq(:once)
  end

  it 'has valid_in_context? default to true' do
    expect(validator.valid_in_context?).to eq(true)
  end

  it 'has a pattern of nil' do
    expect(validator.pattern).to be_nil
  end

  it 'has a pattern_ignore of nil' do
    expect(validator.pattern_ignore).to be_nil
  end

  describe '.prepare_invoke!' do
    it 'registers the spinner only once' do
      expect(validator).to receive(:spinner).once

      validator.prepare_invoke!
      validator.prepare_invoke!
      validator.prepare_invoke!
    end
  end

  describe '.parse_targets' do
    subject(:target_files) { validator.parse_targets }

    let(:validator_options) { { targets: targets } }
    let(:pattern) { '**/**.pp' }

    RSpec.shared_examples 'a parsed target list in an invalid context' do |expected_skipped_targets = nil|
      before(:each) do
        allow(validator).to receive(:valid_in_context?).and_return(false)
      end

      it 'returns all targets as skipped' do
        expect(target_files[0]).to be_empty
        if expected_skipped_targets.nil?
          expect(target_files[1]).to eq(targets)
        else
          expect(target_files[1]).to eq(expected_skipped_targets)
        end
        expect(target_files[2]).to be_empty
      end
    end

    before(:each) do
      allow(validator).to receive(:pattern).and_return(pattern)
      allow(PDK::Util).to receive(:canonical_path).and_wrap_original do |_m, *args|
        args[0]
      end
    end

    context 'when given no targets' do
      let(:targets) { [] }

      context 'when empty targets are not allowed' do
        let(:glob_pattern) { File.join(context_root, validator.pattern) }
        let(:files) { [File.join('manifests', 'init.pp')] }
        let(:globbed_files) { files.map { |file| File.join(context_root, file) } }

        before(:each) do
          allow(validator).to receive(:allow_empty_targets?).and_return(false)
          allow(PDK::Util::Filesystem).to receive(:directory?).and_return(true)
          allow(PDK::Util::Filesystem).to receive(:glob).with(glob_pattern, anything).and_return(globbed_files)
          allow(PDK::Util::Filesystem).to receive(:expand_path).with(context_root).and_return(context_root)
        end

        it 'returns the context root' do
          expect(target_files[0]).to eq(files)
        end
      end

      context 'when empty targets are allowed' do
        before(:each) do
          allow(validator).to receive(:allow_empty_targets?).and_return(true)
        end

        it 'returns an empty target list' do
          expect(target_files[0]).to eq([])
        end
      end

      it_behaves_like 'a parsed target list in an invalid context', ["path/to/test/module"]
    end

    context 'when the globbed files include files matching the default ignore list' do
      let(:targets) { [] }
      let(:glob_pattern) { File.join(context_root, validator.pattern) }
      let(:files) { [File.join('manifests', 'init.pp')] }
      let(:fixture_file) { File.join(context_root, 'spec', 'fixtures', 'modules', 'test', 'manifests', 'init.pp') }
      let(:pkg_file) { File.join(context_root, 'pkg', 'my-module-0.0.1', 'manifests', 'init.pp') }
      let(:globbed_files) do
        [
          File.join(context_root, 'manifests', 'init.pp'),
          fixture_file,
          pkg_file,
        ]
      end

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).and_return(true)
        allow(PDK::Util::Filesystem).to receive(:glob).with(glob_pattern, anything).and_return(globbed_files)
        allow(PDK::Util::Filesystem).to receive(:expand_path).with(context_root).and_return(context_root)
      end

      it 'does not return the files under spec/fixtures/' do
        expect(target_files[0]).not_to include(a_string_including('spec/fixtures'))
      end

      it 'does not return the files under pkg/' do
        expect(target_files[0]).not_to include(a_string_including('pkg/'))
      end

      it_behaves_like 'a parsed target list in an invalid context', ["path/to/test/module"]
    end

    context 'when given specific targets' do
      let(:targets) { ['target1.pp', 'target2/'] }
      let(:glob_pattern) { File.join(context_root, validator.pattern) }
      let(:targets2) { [File.join('target2', 'target.pp')] }
      let(:globbed_target2) { targets2.map { |target| File.join(context_root, target) } }

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:glob).with(glob_pattern, anything).and_return(globbed_target2)
        allow(PDK::Util::Filesystem).to receive(:directory?).with('target1.pp').and_return(false)
        allow(PDK::Util::Filesystem).to receive(:directory?).with('target2/').and_return(true)
        allow(PDK::Util::Filesystem).to receive(:file?).with('target1.pp').and_return(true)

        targets.map do |t|
          allow(PDK::Util::Filesystem).to receive(:expand_path).with(t).and_return(File.join(context_root, t))
        end

        Array[validator.pattern].flatten.map do |p|
          allow(PDK::Util::Filesystem).to receive(:expand_path).with(p).and_return(File.join(context_root, p))
        end
      end

      it 'returns the targets' do
        expect(target_files[0]).to eq(targets2)
        expect(target_files[1]).to eq(['target1.pp'])
        expect(target_files[2]).to be_empty
      end

      it_behaves_like 'a parsed target list in an invalid context'
    end

    context 'when given specific targets which are not in the glob_pattern' do
      let(:pattern) { ['metadata.json', 'tasks/*.json'] }
      let(:targets) { ['target1.pp', 'target2/'] }

      before(:each) do
        # The glob simulates a module with a metadata.json
        allow(PDK::Util::Filesystem).to receive(:glob).with(File.join(context_root, 'metadata.json'), anything).and_return([File.join(context_root, 'metadata.json')])
        # The glob simulates a module without any tasks
        allow(PDK::Util::Filesystem).to receive(:glob).with(File.join(context_root, 'tasks/*.json'), anything).and_return([])
        allow(PDK::Util::Filesystem).to receive(:directory?).with('target1.pp').and_return(false)
        allow(PDK::Util::Filesystem).to receive(:directory?).with('target2/').and_return(true)
        allow(PDK::Util::Filesystem).to receive(:file?).with('target1.pp').and_return(true)

        targets.map do |t|
          allow(PDK::Util::Filesystem).to receive(:expand_path).with(t).and_return(File.join(context_root, t))
        end

        Array[validator.pattern].flatten.map do |p|
          allow(PDK::Util::Filesystem).to receive(:expand_path).with(p).and_return(File.join(context_root, p))
        end
      end

      it 'returns all targets as skipped' do
        expect(target_files[0]).to be_empty
        expect(target_files[1]).to eq(targets)
        expect(target_files[2]).to be_empty
      end

      it_behaves_like 'a parsed target list in an invalid context'
    end

    context 'when given specific targets which are case insensitive on a case insensitive file system' do
      let(:targets) { ['target2/'] }
      let(:glob_pattern) { File.join(context_root, validator.pattern) }
      let(:real_targets) { [File.join('target2', 'target.pp')] }
      let(:globbed_targets) { real_targets.map { |target| File.join(context_root, target) } }

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:glob).with(glob_pattern, anything).and_return(globbed_targets)
        allow(PDK::Util::Filesystem).to receive(:directory?).and_return(true)
        targets.map do |t|
          allow(PDK::Util::Filesystem).to receive(:expand_path).with(t).and_return(File.join(context_root, t))
          # PDK::Util.canonical_path will then convert the case-insensitive paths
          # back to their "real" on-disk names. In this case, lowercase
          expect(PDK::Util).to receive(:canonical_path).with(t.upcase).and_return(t)
        end

        Array[validator.pattern].flatten.map do |p|
          allow(PDK::Util::Filesystem).to receive(:expand_path).with(p).and_return(File.join(context_root, p))
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
        allow(PDK::Util::Filesystem).to receive(:glob).with(File.join(context_root, validator.pattern), anything).and_return(globbed_target2)
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
      let(:pattern) { nil }

      it 'returns the target as-is' do
        expect(target_files[0]).to eq(['random'])
        expect(target_files[1]).to be_empty
        expect(target_files[2]).to be_empty
      end
    end

    context 'when specifying an ignore pattern' do
      before(:each) do
        allow(validator).to receive(:pattern_ignore).and_return('/plans/**/**.pp')

        allow(PDK::Util::Filesystem).to receive(:directory?).and_return(true)
        allow(PDK::Util::Filesystem).to receive(:glob).with(glob_pattern, anything).and_return(globbed_files)
        allow(PDK::Util::Filesystem).to receive(:expand_path).with(context_root).and_return(context_root)
      end

      let(:targets) { [] }
      let(:glob_pattern) { File.join(context_root, validator.pattern) }
      let(:files) do
        [
          File.join('manifests', 'init.pp'),
          File.join('plans', 'foo.pp'),
          File.join('plans', 'nested', 'thing.pp'),
        ]
      end
      let(:globbed_files) { files.map { |file| File.join(context_root, file) } }

      it 'does not match the ignored files' do
        expect(target_files[0].count).to eq(1)
        expect(target_files[0]).to eq([File.join('manifests', 'init.pp')])
      end
    end
  end

  it 'has an ignore_dotfiles? of true' do
    expect(validator.ignore_dotfiles?).to eq(true)
  end

  describe '.spinner_text' do
    it 'returns a String' do
      expect(validator.spinner_text).to be_a(String)
    end
  end

  describe '.spinner' do
    context 'when spinners are enabled' do
      before(:each) do
        allow(validator).to receive(:spinners_enabled?).and_return(true)
      end

      it 'returns a TTY Spinner with spinner text' do
        obj = validator.spinner

        require 'pdk/cli/util/spinner'
        expect(obj).to be_a(TTY::Spinner)
        expect(obj.message).to include(validator.spinner_text)
      end
    end

    context 'when spinners are disabled' do
      before(:each) do
        allow(validator).to receive(:spinners_enabled?).and_return(false)
      end

      it 'returns nil' do
        expect(validator.spinner).to be_nil
      end
    end
  end

  describe '.process_skipped' do
    let(:report) { PDK::Report.new }
    let(:targets) { %w[abc 123] }
    let(:validator_name) { 'mock-validator' }

    before(:each) do
      allow(validator).to receive(:name).and_return(validator_name)
    end

    it 'logs a debug message per target' do
      expect(PDK.logger).to receive(:debug).with(%r{#{targets[0]}})
      expect(PDK.logger).to receive(:debug).with(%r{#{targets[1]}})

      validator.process_skipped(report, targets)
    end

    it 'adds a report event per target' do
      validator.process_skipped(report, targets)

      expect(report.events[validator_name][0].file).to eq(targets[0])
      expect(report.events[validator_name][1].file).to eq(targets[1])
    end
  end

  describe '.process_invalid' do
    let(:report) { PDK::Report.new }
    let(:targets) { %w[abc 123] }
    let(:validator_name) { 'mock-validator' }

    before(:each) do
      allow(validator).to receive(:name).and_return(validator_name)
    end

    it 'logs a debug message per target' do
      expect(PDK.logger).to receive(:debug).with(%r{#{targets[0]}})
      expect(PDK.logger).to receive(:debug).with(%r{#{targets[1]}})

      validator.process_invalid(report, targets)
    end

    it 'adds a report event per target' do
      validator.process_invalid(report, targets)

      expect(report.events[validator_name][0].file).to eq(targets[0])
      expect(report.events[validator_name][1].file).to eq(targets[1])
    end
  end

  it 'has an allow_empty_targets? of false' do
    expect(validator.allow_empty_targets?).to eq(false)
  end
end
