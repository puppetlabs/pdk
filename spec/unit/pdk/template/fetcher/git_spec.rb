require 'spec_helper'
require 'pdk/template/fetcher/git'

describe PDK::Template::Fetcher::Git do
  subject(:fetcher) { described_class.new(template_uri, pdk_context) }

  let(:uri_path) { '/some/path' }
  let(:template_uri) { PDK::Util::TemplateURI.new(uri_path) }
  let(:pdk_context) { PDK::Context::None.new(nil) }

  describe '.fetchable?' do
    subject(:fetchable) { described_class.fetchable?(template_uri) }

    context 'given a git based URI' do
      let(:template_uri) { PDK::Util::TemplateURI.new(PDK::Util::TemplateURI::PDK_TEMPLATE_URL) }

      it 'is fetchable' do
        expect(fetchable).to be true
      end
    end

    context 'given a non-git based URI' do
      let(:template_uri) { PDK::Util::TemplateURI.new('/some/path') }

      it 'is not fetchable' do
        expect(fetchable).to be false
      end
    end
  end

  describe '.fetch!' do
    let(:ref) { 'main' }
    let(:full_ref) { '123456789abcdef' }

    before do
      allow(PDK::Util::Git).to receive(:describe).and_return('git-ref')
    end

    context 'given a work tree' do
      before do
        allow(PDK::Util::Git).to receive(:work_tree?).with(uri_path).and_return(true)
      end

      it 'does not clone the repository' do
        expect(PDK::Util::Git).not_to receive(:git).with('clone', anything, anything)
        fetcher.fetch!
      end

      it 'warns the user' do
        expect(logger).to receive(:warn).with(a_string_matching(/has a work-tree; skipping git reset./i))
        fetcher.fetch!
      end

      it 'is not temporary' do
        fetcher.fetch!
        expect(fetcher.temporary).to be false
      end

      it 'uses the path from the uri' do
        fetcher.fetch!
        expect(fetcher.path).to eq(uri_path)
      end

      it 'sets template-ref and template-url in the metadata' do
        fetcher.fetch!
        expect(fetcher.metadata).to include('template-ref' => 'git-ref', 'template-url' => uri_path)
      end
    end

    context 'given a remote repository' do
      let(:tmp_dir) { File.join('/', 'path', 'to', 'workdir') }
      let(:actual_tmp_dir) { File.join('/', 'actual', 'path', 'to', 'workdir') }

      before do
        allow(PDK::Util::Git).to receive(:work_tree?).with(uri_path).and_return(false)

        # tmp_dir doesn't actually exist so mock it out
        allow(PDK::Util::Filesystem).to receive(:exist?).and_call_original
        allow(PDK::Util::Filesystem).to receive(:exist?).with(tmp_dir).and_return(true)

        allow(PDK::Util::Windows::File).to receive(:get_long_pathname).with(tmp_dir).and_return(actual_tmp_dir)

        allow(PDK::Util::Filesystem).to receive(:expand_path).and_call_original
        allow(PDK::Util::Filesystem).to receive(:expand_path).with(tmp_dir).and_return(actual_tmp_dir)

        expect(PDK::Util).to receive(:make_tmpdir_name).with('pdk-templates').and_return(tmp_dir)
        allow(PDK::Util::Git).to receive(:git).with('clone', anything, tmp_dir).and_return(exit_code: 0, stdout: '', stderr: '')
      end

      context 'and the git clone fails' do
        before do
          expect(PDK::Util::Git).to receive(:git).with('clone', anything, tmp_dir).and_return(exit_code: 1, stdout: 'clone_stdout', stderr: 'clone_stderr')
        end

        it 'logs the output of the git clone' do
          expect(logger).to receive(:error).with(a_string_matching(/clone_stdout/))
          expect(logger).to receive(:error).with(a_string_matching(/clone_stderr/))
          expect { fetcher.fetch! }.to raise_error(StandardError)
        end

        it 'raises a fatal error' do
          expect { fetcher.fetch! }.to raise_error(PDK::CLI::FatalError, /Unable to clone git repository/i)
        end
      end

      context 'when the template workdir is clean' do
        before do
          allow(PDK::Util::Git).to receive(:work_dir_clean?).with(tmp_dir).and_return(true)
          allow(Dir).to receive(:chdir).with(tmp_dir).and_yield
          allow(PDK::Util::Git).to receive(:ls_remote).with(tmp_dir, ref).and_return(full_ref)
        end

        context 'and the git reset succeeds' do
          before do
            allow(PDK::Util::Git).to receive(:git).with('reset', '--hard', full_ref).and_return(exit_code: 0)
          end

          it 'is temporary' do
            fetcher.fetch!
            expect(fetcher.temporary).to be true
          end

          it 'uses the full path on disk' do
            fetcher.fetch!
            expect(fetcher.path).to eq(actual_tmp_dir)
          end

          it 'sets template-ref and template-url in the metadata' do
            fetcher.fetch!
            expect(fetcher.metadata).to include('template-ref' => 'git-ref', 'template-url' => uri_path)
          end
        end

        context 'and the git reset fails' do
          before do
            allow(PDK::Util::Git).to receive(:git).with('reset', '--hard', full_ref).and_return(exit_code: 1, stdout: 'reset_stdout', stderr: 'reset_stderr')
          end

          it 'logs the output of the git reset' do
            expect(logger).to receive(:error).with(a_string_matching(/reset_stdout/))
            expect(logger).to receive(:error).with(a_string_matching(/reset_stderr/))
            expect { fetcher.fetch! }.to raise_error(StandardError)
          end

          it 'raises a fatal error' do
            expect { fetcher.fetch! }.to raise_error(PDK::CLI::FatalError, /Unable to checkout/i)
          end
        end
      end

      context 'when the template workdir is not clean' do
        before do
          allow(PDK::Util::Git).to receive(:work_dir_clean?).with(tmp_dir).and_return(false)
        end

        it 'warns the user' do
          expect(logger).to receive(:warn).with(a_string_matching(/uncommitted changes found/i))
          fetcher.fetch!
        end

        it 'is temporary' do
          fetcher.fetch!
          expect(fetcher.temporary).to be true
        end

        it 'uses the full path on disk' do
          fetcher.fetch!
          expect(fetcher.path).to eq(actual_tmp_dir)
        end

        it 'sets template-ref and template-url in the metadata' do
          fetcher.fetch!
          expect(fetcher.metadata).to include('template-ref' => 'git-ref', 'template-url' => uri_path)
        end
      end
    end
  end
end
