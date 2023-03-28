require 'spec_helper'
require 'pdk/util/version'

describe PDK::Util::Version do
  context 'Getting the version_string' do
    subject(:version_string) { described_class.version_string }

    it { is_expected.not_to be_nil }
  end

  context 'when running from a checkout' do
    before(:each) do
      allow(PDK::Util).to receive(:find_upwards).and_return('/tmp/package/PDK_VERSION')
      allow(PDK::Util::Filesystem).to receive(:exist?).with('/tmp/package/PDK_VERSION').and_return(false)
      allow(PDK::Util::Filesystem).to receive(:directory?).with(%r{.git\Z}).and_return(true)

      result = instance_double(Hash)
      allow(result).to receive(:[]).with(:stdout).and_return('git_hash')
      allow(result).to receive(:[]).with(:exit_code).and_return(0)

      allow(PDK::Util::Git).to receive(:git).with('--git-dir', %r{.git\Z}, 'describe', '--all', '--long', '--always').and_return(result)
    end

    describe '#git_ref' do
      it { expect(described_class.git_ref).to eq 'git_hash' }
    end

    describe '#pkg_sha' do
      it { expect(described_class.pkg_sha).to be_nil }
    end
  end

  context 'when running from a package' do
    before(:each) do
      allow(PDK::Util).to receive(:find_upwards).and_return('/tmp/package/PDK_VERSION')
      allow(PDK::Util::Filesystem).to receive(:exist?).with('/tmp/package/PDK_VERSION').and_return(true)
      allow(PDK::Util::Filesystem).to receive(:read_file).with('/tmp/package/PDK_VERSION').and_return('0.1.2.3.4.pkg_hash')
      allow(PDK::Util::Filesystem).to receive(:directory?).with(%r{.git\Z}).and_return(false)
      expect(PDK::CLI::Exec).not_to receive(:git)
    end

    describe '#git_ref' do
      it { expect(described_class.git_ref).to be_nil }
    end

    describe '#pkg_sha' do
      it { expect(described_class.pkg_sha).to eq 'pkg_hash' }
    end
  end
end
