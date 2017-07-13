require 'spec_helper'
require 'stringio'

shared_context 'a valid answer file' do
  before(:each) do
    allow(PDK::Util).to receive(:package_install?).and_return(false)
    allow(File).to receive(:file?).with(default_path).and_return(true)
    allow(File).to receive(:zero?).with(default_path).and_return(false)
    allow(File).to receive(:readable?).with(default_path).and_return(true)
    allow(File).to receive(:read).with(default_path).and_return('{"question": "answer"}')
  end

  subject(:answer_file) { described_class.new }
end

describe PDK::AnswerFile do
  let(:default_path) { File.join(PDK::Util.cachedir, 'answers.json') }

  describe '#initialize' do
    context 'when not provided a path to an answer file' do
      it 'uses the default path' do
        expect(described_class.new).to have_attributes(answer_file_path: default_path)
      end
    end

    context 'when provided a path to an answer file' do
      let(:path) { '/path/to/answers.json' }

      it 'uses the provided path' do
        expect(described_class.new(path)).to have_attributes(answer_file_path: path)
      end
    end
  end

  describe '#read_from_disk' do
    context 'when the answer file does not exist' do
      before(:each) do
        allow(PDK::Util).to receive(:package_install?).and_return(false)
        allow(File).to receive(:file?).with(default_path).and_return(false)
      end

      it 'creates an empty set of answers' do
        expect(described_class.new).to have_attributes(answers: {})
      end
    end

    context 'when the answer file exists' do
      before(:each) do
        allow(PDK::Util).to receive(:package_install?).and_return(false)
        allow(File).to receive(:file?).with(default_path).and_return(true)
      end

      context 'and contains no data' do
        before(:each) do
          allow(File).to receive(:zero?).with(default_path).and_return(true)
        end

        it 'creates an empty set of answers' do
          expect(described_class.new).to have_attributes(answers: {})
        end
      end

      context 'and is unreadable' do
        before(:each) do
          allow(File).to receive(:zero?).with(default_path).and_return(false)
          allow(File).to receive(:readable?).with(default_path).and_return(false)
        end

        it 'raises a FatalError' do
          expect { described_class.new }.to raise_error(PDK::CLI::FatalError, %r{unable to open .+ for reading}i)
        end
      end

      context 'and is readable' do
        let(:file_contents) {}

        before(:each) do
          allow(File).to receive(:zero?).with(default_path).and_return(false)
          allow(File).to receive(:readable?).with(default_path).and_return(true)
          allow(File).to receive(:read).with(default_path).and_return(file_contents)
        end

        context 'but contains invalid JSON' do
          let(:file_contents) { 'this is not JSON' }
          let(:warning_message) { a_string_matching(%r{answer file .+ did not contain valid JSON}i) }

          it 'warns the user that the file could not be parsed' do
            expect(logger).to receive(:warn).with(warning_message)

            described_class.new
          end

          it 'creates a new empty set of answers' do
            allow(logger).to receive(:warn).with(warning_message)

            expect(described_class.new).to have_attributes(answers: {})
          end
        end

        context 'but contains valid JSON that is not a Hash of answers' do
          let(:file_contents) { '["this", "is", "an", "array"]' }
          let(:warning_message) { a_string_matching(%r{answer file .+ did not contain a valid set of answers}i) }

          it 'warns the user that the answers are invalid' do
            expect(logger).to receive(:warn).with(warning_message)

            described_class.new
          end

          it 'creates a new empty set of answers' do
            allow(logger).to receive(:warn).with(warning_message)

            expect(described_class.new).to have_attributes(answers: {})
          end
        end

        context 'and contains a valid JSON Hash of answers' do
          let(:file_contents) { '{"question": "answer"}' }

          it 'populates the answer set with the values from the file' do
            expect(described_class.new).to have_attributes(answers: { 'question' => 'answer' })
          end
        end
      end
    end
  end

  describe '#[]' do
    include_context 'a valid answer file'

    it 'returns the answer to the question if stored' do
      expect(answer_file['question']).to eq('answer')
    end

    it 'returns nil to the question if not stored' do
      expect(answer_file['unknown question']).to be_nil
    end
  end

  describe '#update!' do
    include_context 'a valid answer file'

    before(:each) do
      allow(answer_file).to receive(:save_to_disk)
    end

    it 'takes a hash of new answers and merges it into the existing answer set' do
      answer_file.update!('another question' => 'different answer')

      expect(answer_file).to have_attributes(answers: { 'question' => 'answer', 'another question' => 'different answer' })
    end

    it 'raises a FatalError if not passed a Hash' do
      expect {
        answer_file.update!('an answer without a question')
      }.to raise_error(PDK::CLI::FatalError, %r{answer file can only be updated with a hash}i)
    end
  end

  describe '#save_to_disk' do
    include_context 'a valid answer file'

    context 'when the file can be written to' do
      let(:fake_file) { StringIO.new }

      before(:each) do
        allow(File).to receive(:open).with(default_path, 'w').and_yield(fake_file)
      end

      it 'writes the answer set to disk' do
        answer_file.update!

        fake_file.rewind
        expect(fake_file.read).not_to be_empty
      end

      it 'writes out the answers as valid JSON' do
        answer_file.update!

        fake_file.rewind
        expect(JSON.parse(fake_file.read)).to eq('question' => 'answer')
      end
    end

    context 'when an IOError is raised' do
      before(:each) do
        allow(File).to receive(:open).with(any_args).and_call_original
        allow(File).to receive(:open).with(default_path, 'w').and_raise(IOError, 'some error message')
      end

      it 'raises a FatalError' do
        message = %r{\Aunable to write '#{Regexp.escape(default_path)}': .*some error message}i
        expect { answer_file.update! }.to raise_error(PDK::CLI::FatalError, message)
      end
    end

    context 'when a SystemCallError is raised' do
      before(:each) do
        allow(File).to receive(:open).with(any_args).and_call_original
        allow(File).to receive(:open).with(default_path, 'w').and_raise(SystemCallError, 'some other error')
      end

      it 'raises a FatalError' do
        message = %r{\Aunable to write '#{Regexp.escape(default_path)}': .*some other error}i
        expect { answer_file.update! }.to raise_error(PDK::CLI::FatalError, message)
      end
    end
  end
end
