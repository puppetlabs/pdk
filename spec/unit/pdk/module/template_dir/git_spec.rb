require 'spec_helper'
require 'pdk/module/template_dir/git'

describe PDK::Module::TemplateDir::Git do
  subject(:template_dir) do
    described_class.new(uri, module_metadata, true) do |foo|
      # block does nothing
    end
  end

  let(:path_or_url) { File.join('/', 'path', 'to', 'templates') }
  let(:uri) { PDK::Util::TemplateURI.new(path_or_url) }
  let(:tmp_path) { File.join('/', 'tmp', 'path') }

  let(:module_metadata) do
    {
      'name' => 'foo-bar',
      'version' => '0.1.0',
    }
  end

  let(:config_defaults) do
    <<-EOS
      appveyor.yml:
        environment:
          PUPPET_GEM_VERSION: "~> 4.0"
      foo:
        attr:
          - val: 1
    EOS
  end

  describe '.checkout_template_ref' do
    # Note that checkout_template_ref is a private method

    let(:path) { File.join('/', 'path', 'to', 'workdir') }
    let(:ref) { '12345678' }
    let(:full_ref) { '123456789abcdef' }

    before(:each) do
      allow(PDK::Util::Git).to receive(:work_tree?).with(path_or_url).and_return(true)
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(described_class).to receive(:clone_template_repo).and_return(path)
      allow(PDK::Util::Git).to receive(:repo?).with(anything).and_return(true)
      allow(PDK::Util::Filesystem).to receive(:directory?).with(anything).and_return(true)
      allow(PDK::Util::Filesystem).to receive(:rm_rf).with(path)
      allow(described_class).to receive(:validate_module_template!)
      allow(PDK::Util::Git).to receive(:describe).and_return('git-ref')
      # rubocop:enable RSpec/AnyInstance
    end

    context 'when the template workdir is clean' do
      before(:each) do
        allow(PDK::Util::Git).to receive(:work_dir_clean?).with(path).and_return(true)
        allow(Dir).to receive(:chdir).with(path).and_yield
        allow(PDK::Util::Git).to receive(:ls_remote).with(path, ref).and_return(full_ref)
      end

      context 'and the git reset succeeds' do
        before(:each) do
          allow(PDK::Util::Git).to receive(:git).with('reset', '--hard', full_ref).and_return(exit_code: 0)
        end

        it 'does not raise an error' do
          expect {
            template_dir.send(:checkout_template_ref, path, ref)
          }.not_to raise_error
        end
      end

      context 'and the git reset fails' do
        let(:result) { { exit_code: 1, stderr: 'stderr', stdout: 'stdout' } }

        before(:each) do
          allow(PDK::Util::Git).to receive(:git).with('reset', '--hard', full_ref).and_return(result)
        end

        it 'raises a FatalError' do
          expect(logger).to receive(:error).with(result[:stdout])
          expect(logger).to receive(:error).with(result[:stderr])
          expect {
            template_dir.send(:checkout_template_ref, path, ref)
          }.to raise_error(PDK::CLI::FatalError, %r{Unable to checkout '12345678' of git repository at '/path/to/workdir'}i)
        end
      end
    end

    context 'when the template workdir is not clean' do
      before(:each) do
        allow(PDK::Util::Git).to receive(:work_dir_clean?).with(path).and_return(false)
      end

      after(:each) do
        template_dir.send(:checkout_template_ref, path, ref)
      end

      it 'warns the user' do
        expect(logger).to receive(:warn).with(a_string_matching(%r{uncommitted changes found}i))
      end
    end
  end

  describe '.metadata' do
    before(:each) do
      allow(PDK::Util::Version).to receive(:version_string).and_return('0.0.0')
      allow(described_class).to receive(:validate_module_template!).with(uri.shell_path).and_return(true)
    end

    context 'with a git based template directory' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).with(anything).and_return(true)
        allow(PDK::Util::Git).to receive(:repo?).with(path_or_url).and_return(true)
        allow(PDK::Util::Git).to receive(:work_tree?).with(uri.shell_path).and_return(true)
        allow(PDK::Util::Git).to receive(:describe).with(File.join(uri.shell_path, '.git'), Object).and_return('1234abcd')
      end

      context 'pdk data' do
        it 'includes the PDK version and template info' do
          expect(template_dir.metadata).to include('pdk-version' => '0.0.0', 'template-url' => path_or_url, 'template-ref' => '1234abcd')
        end
      end
    end
  end
end
