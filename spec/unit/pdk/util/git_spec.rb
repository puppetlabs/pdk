require 'spec_helper'
require 'pdk/util/git'

describe PDK::Util::Git do
  before do
    described_class.clear_cached_information
  end

  describe '.repo?' do
    subject { described_class.repo?(maybe_repo) }

    let(:maybe_repo) { 'pdk-templates' }

    context 'when maybe_repo is a directory' do
      before do
        allow(PDK::Util::Filesystem).to receive(:directory?).with(maybe_repo).and_return(true)
      end

      context 'when maybe_repo is a bare repository' do
        before do
          allow(described_class).to receive(:git_with_env).with(hash_including('GIT_DIR' => maybe_repo), 'rev-parse', '--is-bare-repository').and_return(result)
          # A bare repo does not have a working tree
          allow(described_class).to receive(:work_tree?).and_return(false)
        end

        context 'when `rev-parse --is-bare-repository` returns true' do
          let(:result) do
            { exit_code: 0, stdout: 'true' }
          end

          it { is_expected.to be_truthy }
        end

        context 'when `rev-parse --is-bare-repository` returns false' do
          let(:result) do
            { exit_code: 0, stdout: 'false' }
          end

          it { is_expected.to be_falsey }
        end

        context 'when `rev-parse --is-bare-repository` exits non-zero' do
          let(:result) do
            { exit_code: 1 }
          end

          it { is_expected.to be_falsey }
        end
      end

      context 'when maybe_repo has a working tree' do
        before do
          allow(described_class).to receive(:git).with('rev-parse', '--is-inside-work-tree').and_return(result)
          # A bare repo does not have a working tree
          allow(described_class).to receive(:bare_repo?).and_return(false)
          # Working tree detection is done in the current directory context so mock the Dir.chdir method call
          allow(Dir).to receive(:chdir).with(maybe_repo).and_yield
        end

        context 'when `rev-parse --is-inside-work-tree` returns true' do
          let(:result) do
            { exit_code: 0, stdout: 'true' }
          end

          it { is_expected.to be_truthy }
        end

        context 'when `rev-parse --is-inside-work-tree` returns false' do
          let(:result) do
            { exit_code: 0, stdout: 'false' }
          end

          it { is_expected.to be_falsey }
        end

        context 'when `rev-parse --is-inside-work-tree` exits non-zero' do
          let(:result) do
            { exit_code: 1 }
          end

          it { is_expected.to be_falsey }
        end
      end

      context 'when maybe_repo has neither a working tree or a bare repository' do
        before do
          allow(described_class).to receive(:bare_repo?).and_return(false)
          allow(described_class).to receive(:work_tree?).and_return(false)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when maybe_repo is not a directory' do
      before do
        allow(PDK::Util::Filesystem).to receive(:directory?).with(maybe_repo).and_return(false)
        allow(described_class).to receive(:git).with('ls-remote', '--exit-code', maybe_repo).and_return(result)
      end

      context 'when `ls-remote` exits zero' do
        let(:result) do
          { exit_code: 0 }
        end

        it { is_expected.to be_truthy }
      end

      context 'when `ls-remote` exits non-zero' do
        let(:result) do
          { exit_code: 2 }
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '.ls_remote' do
    subject { described_class.ls_remote(repo, ref) }

    let(:repo) { 'https://github.com/puppetlabs/pdk-templates' }
    let(:ref) { 'main' }

    before do
      allow(described_class).to receive(:git).with('ls-remote', '--refs', repo, ref).and_return(git_result)
    end

    context 'when the repo is unavailable' do
      let(:git_result) do
        {
          exit_code: 1,
          stdout: 'some stdout text',
          stderr: 'some stderr text',
        }
      end

      it 'raises an ExitWithError exception' do
        expect(logger).to receive(:error).with(git_result[:stdout])
        expect(logger).to receive(:error).with(git_result[:stderr])

        expect do
          described_class.ls_remote(repo, ref)
        end.to raise_error(PDK::CLI::ExitWithError, /unable to access the template repository/i)
      end
    end

    context 'when the repo is available' do
      let(:git_result) do
        {
          exit_code: 0,
          stdout: [
            "main-sha\trefs/heads/main",
            "mainful-sha\trefs/heads/mainful"
          ].join("\n"),
        }
      end

      it 'returns only the SHA for the exact ref match' do
        expect(subject).to eq('main-sha')
      end
    end
  end
end
