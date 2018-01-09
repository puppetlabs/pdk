require 'spec_helper'

describe PDK::Util::Git do
  describe '.repo_exists?' do
    subject { described_class.repo_exists?(repo) }

    let(:repo) { 'pdk-templates' }

    before(:each) do
      allow(described_class).to receive(:git).with('ls-remote', '--exit-code', repo).and_return(result)
    end

    context 'when git ls-remote finds refs in the repository' do
      let(:result) do
        { exit_code: 0 }
      end

      it { is_expected.to be_truthy }
    end

    context 'when git ls-remote can not find any refs in the repository' do
      let(:result) do
        { exit_code: 2 }
      end

      it { is_expected.to be_falsey }
    end
  end
end
