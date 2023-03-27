require 'spec_helper'
require 'pdk/util'

describe PDK::Bolt do
  describe '.bolt_project_root?' do
    # We use NUL here because that should never be a valid directory name. But it will work with RSpec mocking.
    let(:test_path) { '\x00path/test' }

    before(:each) do
      allow(PDK::Util::Filesystem).to receive(:file?).and_call_original
    end

    # Directories which indicate a bolt project
    ['Boltdir'].each do |testcase|
      it "detects the directory #{testcase} as being the root of a bolt project" do
        path = File.join(test_path, testcase)
        allow(PDK::Util::Filesystem).to receive(:directory?).with(path).and_return(true)
        expect(described_class.bolt_project_root?(path)).to eq(true)
      end
    end

    # Directories which do not indicate a bolt project
    ['boltdir', 'Boltdir/something'].each do |testcase|
      it "detects the directory #{testcase} as not being the root of a bolt project" do
        path = File.join(test_path, testcase)
        allow(PDK::Util::Filesystem).to receive(:directory?).with(path).and_return(true)
        expect(described_class.bolt_project_root?(path)).to eq(false)
      end
    end

    # Files which indicate a bolt project
    ['bolt.yaml'].each do |testcase|
      it "detects ./#{testcase} as being in the root of a bolt project" do
        allow(PDK::Util::Filesystem).to receive(:file?).with(File.join(test_path, testcase)).and_return(true)
        expect(described_class.bolt_project_root?(test_path)).to eq(true)
      end
    end

    # Files which do not indicate a bolt project
    ['Puppetfile', 'environment.conf', 'metadata.json'].each do |testcase|
      it "detects ./#{testcase} as not being in the root of a bolt project" do
        allow(PDK::Util::Filesystem).to receive(:file?).with(File.join(test_path, testcase)).and_return(true)
        expect(described_class.bolt_project_root?(test_path)).to eq(false)
      end
    end

    it 'uses the current directory if a directory is not specified' do
      expect(PDK::Util::Filesystem).to receive(:file?) { |path| expect(path).to start_with(Dir.pwd) }.at_least(:once)
      described_class.bolt_project_root?
    end
  end
end
