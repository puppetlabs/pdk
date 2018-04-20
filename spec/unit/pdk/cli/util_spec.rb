require 'spec_helper'
require 'pdk/cli/util'

describe PDK::CLI::Util do
  describe '.ensure_in_module!' do
    subject(:ensure_in_module) { described_class.ensure_in_module!(options) }

    let(:error_msg) { a_string_matching(%r{no metadata\.json found}) }
    let(:options) { {} }

    context 'when a metadata.json exists' do
      before(:each) do
        allow(PDK::Util).to receive(:module_root).and_return('something')
      end

      it 'does not raise an error' do
        expect { ensure_in_module }.not_to raise_error
      end
    end

    context 'when there is no metadata.json' do
      before(:each) do
        allow(PDK::Util).to receive(:module_root).and_return(nil)
        allow(File).to receive(:directory?).with(anything).and_return(false)
      end

      context 'when passed :check_module_layout => true' do
        let(:options) { { check_module_layout: true } }

        %w[manifests lib tasks facts.d functions types].each do |dir|
          context "when the current directory contains a '#{dir}' directory" do
            before(:each) do
              allow(File).to receive(:directory?).with(dir).and_return(true)
            end

            it 'does not raise an error' do
              expect { ensure_in_module }.not_to raise_error
            end
          end
        end

        context 'when the current directory does not contain a module layout' do
          it 'raises an error' do
            expect { ensure_in_module }.to raise_error(PDK::CLI::ExitWithError, error_msg)
          end
        end
      end

      context 'when not passed :check_module_layout' do
        before(:each) do
          allow(File).to receive(:directory?).with(anything).and_return(true)
        end

        it 'raises an error' do
          expect { ensure_in_module }.to raise_error(PDK::CLI::ExitWithError, error_msg)
        end
      end
    end
  end

  describe '.interactive?' do
    subject { described_class.interactive? }

    before(:each) do
      allow(PDK.logger).to receive(:debug?).and_return(false)
      allow($stderr).to receive(:isatty).and_return(true)
      ENV.delete('PDK_FRONTEND')
    end

    context 'by default' do
      it { is_expected.to be_truthy }
    end

    context 'when the logger is in debug mode' do
      before(:each) do
        allow(PDK.logger).to receive(:debug?).and_return(true)
      end

      it { is_expected.to be_falsey }
    end

    context 'when PDK_FRONTEND env var is set to noninteractive' do
      before(:each) do
        ENV['PDK_FRONTEND'] = 'noninteractive'
      end

      it { is_expected.to be_falsey }
    end

    context 'when STDERR is not a TTY' do
      before(:each) do
        allow($stderr).to receive(:isatty).and_return(false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe 'module_version_check' do
    subject(:module_version_check) { described_class.module_version_check }

    before(:each) do
      stub_const('PDK::VERSION', '1.5.0')
      allow(PDK::Util).to receive(:module_pdk_version).and_return(module_pdk_ver)
    end

    context 'if module doesn\'t have pdk-version in metadata' do
      let(:module_pdk_ver) { nil }

      before(:each) do
        expect(logger).to receive(:warn).with(a_string_matching(%r{This module is not PDK compatible. Run `pdk convert` to make it compatible with your version of PDK.}i))
      end

      it 'does not raise an error' do
        expect { module_version_check }.not_to raise_error
      end
    end

    context 'if module version is older than 1.3.1' do
      let(:module_pdk_ver) { '1.2.0' }

      before(:each) do
        expect(logger).to receive(:warn).with(a_string_matching(%r{This module template is out of date. Run `pdk convert` to make it compatible with your version of PDK.}i))
      end

      it 'does not raise an error' do
        expect { module_version_check }.not_to raise_error
      end
    end

    context 'if module version is newer than installed version' do
      let(:module_pdk_ver) { '1.5.1' }

      before(:each) do
        expect(logger).to receive(:warn).with(a_string_matching(%r{This module is compatible with a newer version of PDK. Upgrade your version of PDK to ensure compatibility.}i))
      end

      it 'does not raise an error' do
        expect { module_version_check }.not_to raise_error
      end
    end

    context 'if module version is older than installed version' do
      let(:module_pdk_ver) { '1.3.1' }

      before(:each) do
        expect(logger).to receive(:warn).with(a_string_matching(%r{This module is compatible with an older version of PDK. Run `pdk update` to update it to your version of PDK.}i))
      end

      it 'does not raise an error' do
        expect { module_version_check }.not_to raise_error
      end
    end
  end
end
