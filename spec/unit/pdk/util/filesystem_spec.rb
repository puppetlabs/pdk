require 'spec_helper'
require 'pdk/util/filesystem'
require 'stringio'

describe PDK::Util::Filesystem do
  describe '.read_file' do
    subject(:read_file) { described_class.read_file(path, nil_on_error:) }

    let(:path) { File.join('path', 'to', 'my', 'file') }
    let(:nil_on_error) { false }

    context 'when given a path to a readable file' do
      before do
        allow(File).to receive(:read).with(path, anything).and_return('some content')
      end

      it 'does not raise an error' do
        expect { read_file }.not_to raise_error
      end

      it 'returns the file content' do
        expect(read_file).to eq('some content')
      end
    end

    context 'when given a path to an unreadable file' do
      before do
        allow(File).to receive(:read).with(path, anything).and_raise(Errno::EACCES, 'some error')
      end

      context 'when nil_on_error => false' do
        it 'raises the underlying error' do
          expect { read_file }.to raise_error(Errno::EACCES, /some error/)
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

    before do
      allow(File).to receive(:binwrite).with(path, "#{content}\n")
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
          expect { write_file }.to raise_error(ArgumentError, /String or Pathname/)
        end
      end
    end

    context 'when content is not a String' do
      let(:content) { nil }

      it 'raises an ArgumentError' do
        expect { write_file }.to raise_error(ArgumentError, /content must be a String/)
      end
    end
  end

  describe '.make_executable' do
    subject(:make_executable) { described_class.make_executable(path) }

    let(:path) { File.join('path', 'to', 'my', 'file') }

    context 'when file is writable' do
      before do
        allow(FileUtils).to receive(:chmod)
      end

      it 'does not raise an error' do
        expect { make_executable }.not_to raise_error
      end
    end

    context 'when file is not writable' do
      before do
        allow(FileUtils).to receive(:chmod).and_raise(Errno::EACCES, 'some error')
      end

      it 'raises an error' do
        expect { make_executable }.to raise_error(Errno::EACCES, /some error/)
      end
    end
  end
end
