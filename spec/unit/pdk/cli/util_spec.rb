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
end
