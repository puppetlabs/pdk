require 'spec_helper'

describe PDK::CLI::Exec do
  describe '.execute' do
    let(:command_double) { instance_double(PDK::CLI::Exec::Command, execute!: :exec_result) }

    it 'generates a new PDK::CLI::Exec::Command instance and executes it' do
      allow(PDK::CLI::Exec::Command).to receive(:new).with('some', 'command').and_return(command_double)
      expect(described_class.execute('some', 'command')).to eq(:exec_result)
    end
  end

  describe '.ensure_bin_present!' do
    context 'when the specified binary is present' do
      it 'does not raise an error' do
        allow(TTY::Which).to receive(:exist?).with('/path/to/some/binary_name').and_return(true)

        expect {
          described_class.ensure_bin_present!('/path/to/some/binary_name', 'binary_name')
        }.not_to raise_error
      end
    end

    context 'when the specified binary is absent' do
      it 'raises a FatalError' do
        allow(TTY::Which).to receive(:exist?).with('/path/to/some/binary_name').and_return(false)

        expect {
          described_class.ensure_bin_present!('/path/to/some/binary_name', 'binary_name')
        }.to raise_error(PDK::CLI::FatalError, %r{unable to find `binary_name`}i)
      end
    end
  end

  describe '.try_vendored_bin' do
    subject(:return_value) { described_class.try_vendored_bin(vendored_path, fallback_value) }

    let(:vendored_path) { File.join('path', 'to', 'some', 'vendored', 'binary') }
    let(:fallback_value) { 'fallback' }

    context 'when not part of packaged PDK install' do
      before(:each) do
        allow(PDK::Util).to receive(:package_install?).and_return(false)
      end

      it 'returns the fallback value' do
        expect(return_value).to eq(fallback_value)
      end
    end

    context 'when part of a packaged PDK install' do
      let(:pdk_package_basedir) { '/path/to/the/pdk' }

      before(:each) do
        allow(PDK::Util).to receive(:package_install?).and_return(true)
        allow(PDK::Util).to receive(:pdk_package_basedir).and_return(pdk_package_basedir)
      end

      context 'and the binary is vendored in the package' do
        before(:each) do
          allow(File).to receive(:exist?).with(File.join(pdk_package_basedir, vendored_path)).and_return(true)
        end

        it 'returns the path to the vendored binary' do
          expect(return_value).to eq(File.join(pdk_package_basedir, vendored_path))
        end
      end

      context 'and the binary is not vendored' do
        before(:each) do
          allow(File).to receive(:exist?).with(File.join(pdk_package_basedir, vendored_path)).and_return(false)
        end

        it 'returns the fallback value' do
          expect(return_value).to eq(fallback_value)
        end
      end
    end
  end

  describe '.git_bindir' do
    subject { described_class.git_bindir }

    context 'on a Windows host' do
      before(:each) do
        described_class.instance_variable_set('@git_dir', nil)
        allow(Gem).to receive(:win_platform?).and_return(true)
      end

      it { is_expected.to eq(File.join('private', 'git', 'cmd')) }
    end

    context 'on a POSIX host' do
      before(:each) do
        described_class.instance_variable_set('@git_dir', nil)
        allow(Gem).to receive(:win_platform?).and_return(false)
      end

      it { is_expected.to eq(File.join('private', 'git', 'bin')) }
    end
  end

  describe '.git_bin' do
    context 'on a Windows host' do
      before(:each) do
        described_class.instance_variable_set('@git_dir', nil)
        allow(Gem).to receive(:win_platform?).and_return(true)
      end

      it 'tries to find the vendored git binary' do
        allow(described_class).to receive(:try_vendored_bin).with(File.join(described_class.git_bindir, 'git.exe'), 'git.exe').and_return(:path)

        expect(described_class.git_bin).to eq(:path)
      end
    end

    context 'on a POSIX host' do
      before(:each) do
        described_class.instance_variable_set('@git_dir', nil)
        allow(Gem).to receive(:win_platform?).and_return(false)
      end

      it 'tries to find the vendored git binary' do
        allow(described_class).to receive(:try_vendored_bin).with(File.join(described_class.git_bindir, 'git'), 'git').and_return(:path)

        expect(described_class.git_bin).to eq(:path)
      end
    end
  end

  describe '.git' do
    it 'ensures that the git binary is present' do
      allow(described_class).to receive(:execute).with(any_args)
      expect(described_class).to receive(:ensure_bin_present!).with(described_class.git_bin, 'git')

      described_class.git('test')
    end

    it 'executes git with the supplied arguments' do
      allow(described_class).to receive(:ensure_bin_present!).with(described_class.git_bin, 'git')
      expect(described_class).to receive(:execute).with(described_class.git_bin, 'clone', 'test')

      described_class.git('clone', 'test')
    end
  end

  describe '.bundle_bin' do
    let(:base_path) { File.join('private', 'ruby', '2.1.9', 'bin') }

    context 'on a Windows host' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(true)
      end

      it 'tries to find the vendored bundle binary' do
        allow(described_class).to receive(:try_vendored_bin).with(File.join(base_path, 'bundle.bat'), 'bundle.bat').and_return(:path)

        expect(described_class.bundle_bin).to eq(:path)
      end
    end

    context 'on a POSIX host' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(false)
      end

      it 'tries to find the vendored bundle binary' do
        allow(described_class).to receive(:try_vendored_bin).with(File.join(base_path, 'bundle'), 'bundle').and_return(:path)

        expect(described_class.bundle_bin).to eq(:path)
      end
    end
  end

  describe '.bundle' do
    it 'ensures that the bundler binary is present' do
      allow(described_class).to receive(:execute).with(any_args)
      expect(described_class).to receive(:ensure_bin_present!).with(described_class.bundle_bin, 'bundler')

      described_class.bundle('test')
    end

    it 'executes bundle with the supplied arguments' do
      allow(described_class).to receive(:ensure_bin_present!).with(described_class.bundle_bin, 'bundler')
      expect(described_class).to receive(:execute).with(described_class.bundle_bin, 'install')

      described_class.bundle('install')
    end
  end
end
