require 'spec_helper'
require 'concurrent/configuration'
require 'concurrent/future'
require 'facter-ng'
require 'pdk/analytics/util'

describe PDK::Analytics::Util do
  describe '.fetch_os_async' do
    subject(:result) { described_class.fetch_os_async }

    let(:executor) { Concurrent.new_io_executor }

    before(:each) do
      allow(Concurrent).to receive(:global_io_executor).and_return(executor)
      allow(Facter).to receive(:value).with('os').and_return(os_hash)
    end

    after(:each) do
      executor.shutdown
      executor.wait_for_termination(0.25)
    end

    context 'when facter returns a full os hash' do
      let(:os_hash) { { 'name' => 'CentOS', 'release' => { 'major' => 7 } } }

      it 'returns a string with the OS name and major version' do
        expect(result.value).to eq('CentOS 7')
      end
    end

    context 'when facter returns an os hash with incomplete release information' do
      let(:os_hash) { { 'name' => 'CentOS', 'release' => {} } }

      it 'returns a string with the OS name' do
        expect(result.value).to eq('CentOS')
      end
    end

    context 'when facter returns an os hash with no release information' do
      let(:os_hash) { { 'name' => 'CentOS' } }

      it 'returns a string with the OS name' do
        expect(result.value).to eq('CentOS')
      end
    end

    context 'when facter does not return an os hash' do
      let(:os_hash) { nil }

      it 'returns unknown' do
        expect(result.value).to eq('unknown')
      end
    end
  end
end
