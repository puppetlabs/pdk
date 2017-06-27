require 'spec_helper'
require 'pdk/util/bundler'

RSpec.describe PDK::Util::Bundler do
  before(:each) do
    # Doesn't matter where this is since all the execs get mocked.
    allow(PDK::Util).to receive(:module_root).and_return('/')
  end

  # TODO: deduplicate code in these two methods and extract them to a shared location
  def allow_command(argv, result = nil)
    result ||= { exit_code: 0, stdout: '', stderr: '' }

    command_double = instance_double(PDK::CLI::Exec::Command, 'context=' => true, 'execute!' => result, 'add_spinner' => true)

    allow(PDK::CLI::Exec::Command).to receive(:new).with(*argv).and_return(command_double)
  end

  def expect_command(argv, result = nil, spinner_message = nil)
    result ||= { exit_code: 0, stdout: '', stderr: '' }

    command_double = instance_double(PDK::CLI::Exec::Command, 'context=' => true, 'execute!' => result)

    if spinner_message
      expect(command_double).to receive(:add_spinner).with(spinner_message, any_args)
    end

    expect(PDK::CLI::Exec::Command).to receive(:new).with(*argv).and_return(command_double)
  end

  def bundle_regex
    %r{bundle(\.bat)?$}
  end

  describe '.ensure_bundle!' do
    context 'when there is no Gemfile' do
      before(:each) do
        allow(File).to receive(:file?).with(%r{Gemfile$}).and_return(false)
      end

      it 'does nothing' do
        expect(PDK::CLI::Exec::Command).not_to receive(:new)

        described_class.ensure_bundle!
      end
    end

    context 'when there is no Gemfile.lock' do
      before(:each) do
        allow(File).to receive(:file?).with(%r{Gemfile$}).and_return(true)
        allow(File).to receive(:file?).with(%r{Gemfile\.lock$}).and_return(false)

        allow_command([bundle_regex, 'check', any_args], exit_code: 1)
        allow_command([bundle_regex, 'install', any_args])
      end

      it 'generates Gemfile.lock' do
        expect_command([bundle_regex, 'lock', any_args], nil, %r{resolving gemfile}i)

        described_class.ensure_bundle!
      end
    end

    context 'when there are missing gems' do
      before(:each) do
        allow(File).to receive(:file?).with(%r{Gemfile$}).and_return(true)
        allow(File).to receive(:file?).with(%r{Gemfile\.lock$}).and_return(true)

        allow_command([bundle_regex, 'check', any_args], exit_code: 1)
      end

      it 'installs missing gems' do
        allow(described_class).to receive(:already_bundled?).and_return(false)
        expect_command([bundle_regex, 'install', any_args], nil, %r{installing missing gemfile}i)

        described_class.ensure_bundle!
      end

      it 'only attempts to install the gems once' do
        expect(PDK::CLI::Exec::Command).not_to receive(:new)
        expect(logger).to receive(:debug).with(%r{already been installed})

        described_class.ensure_bundle!
      end
    end

    context 'when there are no missing gems' do
      before(:each) do
        allow(File).to receive(:file?).with(%r{Gemfile$}).and_return(true)
        allow(File).to receive(:file?).with(%r{Gemfile\.lock$}).and_return(true)
        allow(described_class).to receive(:already_bundled?).and_return(false)
      end

      it 'checks for missing but does not install anything' do
        expect_command([bundle_regex, 'check', any_args], nil, %r{checking for missing}i)
        expect(PDK::CLI::Exec::Command).not_to receive(:new).with(bundle_regex, 'install', any_args)

        described_class.ensure_bundle!
      end
    end
  end
end
