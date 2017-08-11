require 'spec_helper'

describe PDK::CLI::Exec do
  describe '#try_vendored_bin' do
    context 'when installed as gem' do
      before(:each) { allow(PDK::Util).to receive(:package_install?).with(no_args).and_return(false) }
      it 'returns the fallback' do
        expect(described_class.try_vendored_bin('something', 'fallback')).to eq 'fallback'
      end
    end
    context 'when installed as package' do
      before(:each) do
        allow(PDK::Util).to receive(:package_install?).with(no_args).and_return(true)
        allow(PDK::Util).to receive(:pdk_package_basedir).with(no_args).and_return('/foo')
      end
      context 'when the file exists in the package' do
        before(:each) do
          expect(File).to receive(:exist?).with('/foo/private/bin/bar').and_return(true)
        end
        it 'returns the full path' do
          expect(described_class.try_vendored_bin('private/bin/bar', 'fallback')).to eq '/foo/private/bin/bar'
        end
      end
      context 'when the file is not in the package' do
        before(:each) do
          expect(File).to receive(:exist?).with('/foo/private/bin/bar').and_return(false)
        end
        it 'returns the full path' do
          expect(described_class.try_vendored_bin('private/bin/bar', 'fallback')).to eq 'fallback'
        end
      end
    end
  end
end
