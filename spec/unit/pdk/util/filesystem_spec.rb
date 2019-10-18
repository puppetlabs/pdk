require 'spec_helper'
require 'pdk/util/filesystem'
require 'stringio'

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

  describe '.write_file' do
    subject(:write_file) { described_class.write_file(path, content) }

    let(:dummy_file) { StringIO.new }
    let(:path) { nil }

    before(:each) do
      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open).with(path, 'wb').and_yield(dummy_file)
    end

    context 'when content is a String' do
      let(:content) { 'something' }

      context 'and the path is a String' do
        let(:path) { File.join('path', 'to', 'my', 'file') }

        it 'does not raise an error' do
          expect { write_file }.not_to raise_error
        end
      end

      context 'and the path is a Pathname' do
        let(:path) { Pathname.new(File.join('path', 'to', 'my', 'file')) }

        it 'does not raise an error' do
          expect { write_file }.not_to raise_error
        end
      end

      context 'and the path is neither a String nor Pathname' do
        it 'raises an ArgumentError' do
          expect { write_file }.to raise_error(ArgumentError, %r{String or Pathname})
        end
      end
    end

    context 'when content is not a String' do
      let(:content) { nil }

      it 'raises an ArgumentError' do
        expect { write_file }.to raise_error(ArgumentError, %r{content must be a String})
      end
    end
  end
end
