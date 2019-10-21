require 'spec_helper'
require 'pdk/util/filesystem'

describe PDK::Util::Filesystem do
  describe '.read_file' do
    subject(:read_file) { described_class.read_file(path, nil_on_error: nil_on_error) }

    let(:path) { File.join('path', 'to', 'my', 'file') }
    let(:nil_on_error) { false }

    context 'when given a path to a readable file' do
      before(:each) do
        allow(File).to receive(:read).with(path).and_return('some content')
      end

      it 'does not raise an error' do
        expect { read_file }.not_to raise_error
      end

      it 'returns the file content' do
        expect(read_file).to eq('some content')
      end
    end

    context 'when given a path to an unreadable file' do
      before(:each) do
        allow(File).to receive(:read).with(path).and_raise(Errno::EACCES, 'some error')
      end

      context 'when nil_on_error => false' do
        it 'raises the underlying error' do
          expect { read_file }.to raise_error(Errno::EACCES, %r{some error})
        end
      end

      context 'when nil_on_error => true' do
        let(:nil_on_error) { true }

        it 'does not raise an error' do
          expect { read_file }.not_to raise_error
        end

        it 'returns nil' do
          expect(read_file).to be_nil
        end
      end
    end
  end
end
