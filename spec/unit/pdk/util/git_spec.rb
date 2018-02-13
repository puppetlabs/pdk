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

  describe '.ls_remote' do
    subject { described_class.ls_remote(repo, ref) }

    let(:repo) { 'https://github.com/puppetlabs/pdk-templates' }
    let(:ref) { 'refs/heads/master' }

    before(:each) do
      allow(described_class).to receive(:git).with('ls-remote', '--refs', repo, ref).and_return(git_result)
    end

    context 'when the repo is unavailable' do
      let(:git_result) do
        {
          exit_code: 1,
          stdout:    'some stdout text',
          stderr:    'some stderr text',
        }
      end

      it 'raises an ExitWithError exception' do
        expect(logger).to receive(:error).with(git_result[:stdout])
        expect(logger).to receive(:error).with(git_result[:stderr])

        expect {
          described_class.ls_remote(repo, ref)
        }.to raise_error(PDK::CLI::ExitWithError, %r{unable to access the template repository}i)
      end
    end

    context 'when the repo is available' do
      let(:git_result) do
        {
          exit_code: 0,
          stdout:    [
            "master-sha\trefs/heads/master",
            "masterful-sha\trefs/heads/masterful",
          ].join("\n"),
        }
      end

      it 'returns only the SHA for the exact ref match' do
        is_expected.to eq('master-sha')
      end
    end
  end
end
