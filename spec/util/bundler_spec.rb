require 'spec_helper'
require 'pdk/util/bundler'

RSpec.describe PDK::Util::Bundler do
  describe '.ensure_bundle!' do
    context 'when there is no Gemfile' do
      before(:each) do
        allow(File).to receive(:file?).with(/Gemfile$/).and_return(false)
      end

      it 'does nothing' do
        expect(PDK::CLI::Exec).to_not receive(:bundle)

        PDK::Util::Bundler.ensure_bundle!
      end
    end

    context 'when there is no Gemfile.lock' do
      before(:each) do
        allow(File).to receive(:file?).with(/Gemfile$/).and_return(true)
        allow(File).to receive(:file?).with(/Gemfile\.lock$/).and_return(false)
        allow(PDK::CLI::Exec).to receive(:bundle).with('check', any_args).and_return({exit_code: 1})
        allow(PDK::CLI::Exec).to receive(:bundle).with('install', any_args).and_return({exit_code: 0})
      end

      it 'generates Gemfile.lock' do
        expect(PDK::CLI::Exec).to receive(:bundle).with('lock', any_args).and_return({exit_code: 0})

        expect { PDK::Util::Bundler.ensure_bundle! }.to output(/resolving gemfile/i).to_stderr
      end
    end

    context 'when there are missing gems' do
      before(:each) do
        allow(File).to receive(:file?).with(/Gemfile$/).and_return(true)
        allow(File).to receive(:file?).with(/Gemfile\.lock$/).and_return(true)
        allow(PDK::CLI::Exec).to receive(:bundle).with('check', any_args).and_return({exit_code: 1})
      end

      it 'installs missing gems' do
        expect(PDK::CLI::Exec).to receive(:bundle).with('install', any_args).and_return({exit_code: 0})

        expect { PDK::Util::Bundler.ensure_bundle! }.to output(/installing missing gemfile/i).to_stderr
      end
    end

    context 'when there are no missing gems' do
      before(:each) do
        allow(File).to receive(:file?).with(/Gemfile$/).and_return(true)
        allow(File).to receive(:file?).with(/Gemfile\.lock$/).and_return(true)
      end

      it 'checks for missing but does not install anything' do
        expect(PDK::CLI::Exec).to receive(:bundle).with('check', any_args).and_return({exit_code: 0})
        expect(PDK::CLI::Exec).to_not receive(:bundle).with('install', any_args)

        expect { PDK::Util::Bundler.ensure_bundle! }.to output(/checking for missing/i).to_stderr
      end
    end
  end
end
