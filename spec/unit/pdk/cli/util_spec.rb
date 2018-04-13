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

  shared_examples_for 'it returns a puppet environment' do
    it 'notifies the user of the ruby version' do
      expect(logger).to receive(:info).with(a_string_matching(%r{using ruby #{Regexp.escape(ruby_version)}}i))
      expect { puppet_env }.not_to raise_error
    end

    it 'notifies the user of the puppet version' do
      expect(logger).to receive(:info).with(a_string_matching(%r{using puppet #{Regexp.escape(puppet_version)}}i))
      expect { puppet_env }.not_to raise_error
    end

    it 'returns the gemset and ruby version' do
      expected_result = {
        gemset:       { puppet: puppet_version },
        ruby_version: ruby_version,
      }
      is_expected.to eq(expected_result)
    end
  end

  describe '.puppet_env_from_opts' do
    subject(:puppet_env) { described_class.puppet_env_from_opts(options) }

    let(:version_result) do
      { ruby_version: ruby_version, gem_version: Gem::Version.new(puppet_version) }
    end

    context 'when puppet-version has been set' do
      let(:options) { { :'puppet-version' => '4.10.10' } }
      let(:ruby_version) { '2.1.9' }
      let(:puppet_version) { '4.10.10' }

      before(:each) do
        allow(PDK::Util::PuppetVersion).to receive(:find_gem_for).with(anything).and_return(version_result)
      end

      it_behaves_like 'it returns a puppet environment'
    end

    context 'when pe-version has been set' do
      let(:options) { { :'pe-version' => '2017.3.1' } }
      let(:ruby_version) { '2.4.3' }
      let(:puppet_version) { '5.3.2' }

      before(:each) do
        allow(PDK::Util::PuppetVersion).to receive(:from_pe_version).with(anything).and_return(version_result)
      end

      it_behaves_like 'it returns a puppet environment'
    end

    context 'when neither puppet-version nor pe-version has been set' do
      let(:options) { {} }

      context 'and a puppet version can be found in the module metadata' do
        let(:ruby_version) { '2.4.3' }
        let(:puppet_version) { '5.3.0' }

        before(:each) do
          allow(PDK::Util::PuppetVersion).to receive(:from_module_metadata).and_return(version_result)
        end

        it 'does not search for the latest available puppet version' do
          expect(PDK::Util::PuppetVersion).not_to receive(:latest_available)
          expect { puppet_env }.not_to raise_error
        end

        it_behaves_like 'it returns a puppet environment'
      end

      context 'and there is no puppet version in the module metadata' do
        let(:ruby_version) { '2.4.3' }
        let(:puppet_version) { '5.5.1' }

        before(:each) do
          allow(PDK::Util::PuppetVersion).to receive(:from_module_metadata).and_return(nil)
          allow(PDK::Util::PuppetVersion).to receive(:latest_available).and_return(version_result)
        end

        it_behaves_like 'it returns a puppet environment'
      end
    end
  end
end
