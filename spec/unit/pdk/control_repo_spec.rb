require 'spec_helper'
require 'pdk/util'

describe PDK::ControlRepo do
  RSpec.shared_examples 'a discoverable control repo' do
    before(:each) do
      allow(PDK::Util).to receive(:find_upwards).with('environment.conf').and_return(environment_path)
      allow(described_class).to receive(:control_repo_root?).and_return(control_repo_root)
    end

    context 'when a environment.conf file can be found upwards' do
      let(:environment_path) { '/path/to/the/repo/environment.conf' }
      let(:control_repo_root) { true }

      it 'returns the path to the directory containing the environment.conf file' do
        is_expected.to eq(File.dirname(environment_path))
      end
    end

    context 'when a environment.conf file could not be found but control repo files can' do
      let(:environment_path) { nil }
      let(:control_repo_root) { true }

      it { is_expected.to eq(Dir.pwd) }
    end

    context 'when a environment.conf file and control repo files could not be found' do
      let(:environment_path) { nil }
      let(:control_repo_root) { false }

      it { is_expected.to be_nil }
    end
  end

  describe '.control_repo_root' do
    context 'with strict_check set to false' do
      subject { described_class.find_control_repo_root(false) }

      it_behaves_like 'a discoverable control repo'
    end

    context 'with strict_check set to true but is not a Bolt project dir' do
      subject { described_class.find_control_repo_root(true) }

      before(:each) do
        allow(PDK::Bolt).to receive(:bolt_project_root?).and_return(false)
      end

      it_behaves_like 'a discoverable control repo'
    end

    context 'with strict_check set to true and is also a Bolt project dir' do
      subject { described_class.find_control_repo_root(true) }

      before(:each) do
        allow(PDK::Util).to receive(:find_upwards).with('environment.conf').and_return(environment_path)
        allow(described_class).to receive(:control_repo_root?).and_return(control_repo_root)
        allow(PDK::Bolt).to receive(:bolt_project_root?).and_return(true)
      end

      context 'when a environment.conf file can be found upwards' do
        let(:environment_path) { '/path/to/the/repo/environment.conf' }
        let(:control_repo_root) { true }

        it { is_expected.to be_nil }
      end

      context 'when a environment.conf file could not be found but control repo files can' do
        let(:environment_path) { nil }
        let(:control_repo_root) { true }

        it { is_expected.to be_nil }
      end

      context 'when a environment.conf file and control repo files could not be found' do
        let(:environment_path) { nil }
        let(:control_repo_root) { false }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '.control_repo_root?' do
    # We use NUL here because that should never be a valid directory name. But it will work with RSpec mocking.
    let(:test_path) { '\x00path/test' }

    before(:each) do
      allow(PDK::Util::Filesystem).to receive(:file?).and_call_original
    end

    # Files which indicate a control repo
    %w[
      Puppetfile
      environment.conf
    ].each do |testcase|
      it "detects #{testcase} as being in the root of a control repo" do
        allow(PDK::Util::Filesystem).to receive(:file?).with(File.join(test_path, testcase)).and_return(true)
        expect(described_class.control_repo_root?(test_path)).to eq(true)
      end
    end

    # Files which do not indicate a control repo
    %w[
      puppetfile
      Environment.conf
      Gemfile
    ].each do |testcase|
      it "detects #{testcase} as not being in the root of a control repo" do
        allow(PDK::Util::Filesystem).to receive(:file?).with(File.join(test_path, testcase)).and_return(true)
        expect(described_class.control_repo_root?(test_path)).to eq(false)
      end
    end

    it 'uses the current directory if a directory is not specified' do
      expect(PDK::Util::Filesystem).to receive(:file?) { |path| expect(path).to start_with(Dir.pwd) }.at_least(:once)
      described_class.control_repo_root?
    end
  end

  describe 'environment_conf_as_config' do
    subject(:config) { described_class.environment_conf_as_config(path) }

    let(:path) { File.join(FIXTURES_DIR, 'control_repo') }

    it 'returns a PDK::Config::IniFile object' do
      expect(config).to be_a(PDK::Config::IniFile)
    end

    context 'with a nil path' do
      let(:path) { File.join(FIXTURES_DIR, 'control_repo') }

      it 'has a modulepath default setting' do
        expect(config['modulepath']).not_to be_nil
      end

      it 'has a manifest default setting' do
        expect(config['manifest']).not_to be_nil
      end
    end
  end
end
