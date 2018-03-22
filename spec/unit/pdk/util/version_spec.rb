# frozen_string_literal: true

require 'spec_helper'

describe PDK::Util::Version do
  context 'Getting the version_string' do
    subject(:version_string) { described_class.version_string }

    it { is_expected.not_to be_nil }
  end

  context 'when running from a checkout' do
    before(:each) do
      allow(PDK::Util).to receive(:find_upwards).and_return('/tmp/package/PDK_VERSION')
      allow(File).to receive(:exist?).with('/tmp/package/PDK_VERSION').and_return(false)
      allow(File).to receive(:directory?).with(%r{.git\Z}).and_return(true)

      result = instance_double('exec_git_describe_result')
      allow(result).to receive(:[]).with(:stdout).and_return('git_hash')
      allow(result).to receive(:[]).with(:exit_code).and_return(0)

      allow(PDK::Util::Git).to receive(:git).with('--git-dir', %r{.git\Z}, 'describe', '--all', '--long').and_return(result)
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
      allow(File).to receive(:exist?).with('/tmp/package/PDK_VERSION').and_return(true)
      allow(File).to receive(:read).with('/tmp/package/PDK_VERSION').and_return('0.1.2.3.4.pkg_hash')
      allow(File).to receive(:directory?).with(%r{.git\Z}).and_return(false)
      allow(PDK::CLI::Exec).to receive(:git).never
    end

    describe '#git_ref' do
      it { expect(described_class.git_ref).to be_nil }
    end

    describe '#pkg_sha' do
      it { expect(described_class.pkg_sha).to eq 'pkg_hash' }
    end
  end
end
