require 'spec_helper'

describe PDK::Report::Event do
  subject(:junit_event) { event.to_junit }

  subject(:text_event) { event.to_text }

  subject { event }

  let(:event) { described_class.new(default_data.merge(data)) }

  let(:default_data) do
    {
      file:   'testfile.rb',
      source: 'test-validator',
      state:  :passed,
    }
  end

  let(:data) { {} }

  context 'when validating arguments' do
    context 'and passed an absolute path to the file being tested' do
      before(:each) do
        expect(PDK::Util).to receive(:module_root).and_return('/path/to/test/module')
      end

      let(:data) do
        {
          file: '/path/to/test/module/lib/some/file.rb',
        }
      end

      it 'converts the path to one relative to the module root' do
        is_expected.to have_attributes(file: 'lib/some/file.rb')
      end
    end

    context 'and not passed a file path' do
      let(:data) do
        {
          file: nil,
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{file not specified})
      end
    end

    context 'and passed a file path that is not a String' do
      let(:data) do
        {
          file: ['/path/to/test/module/lib/some/file.rb'],
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{file must be a string}i)
      end
    end

    context 'and passed an empty string as the file path' do
      let(:data) do
        {
          file: '',
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{file not specified})
      end
    end

    context 'and not passed a source' do
      let(:data) do
        {
          source: nil,
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{source not specified})
      end
    end

    context 'and passed an empty string as the source' do
      let(:data) do
        {
          source: '',
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{source not specified})
      end
    end

    context 'and not passed a state' do
      let(:data) do
        {
          state: nil,
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{state not specified})
      end
    end

    context 'and passed an empty string as the state' do
      let(:data) do
        {
          state: '',
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{state not specified})
      end
    end

    methods = [:pass, :error, :failure, :skipped]

    {
      passed:  :pass,
      error:   :error,
      failure: :failure,
      skipped: :skipped,
    }.each do |state_sym, state_method|
      [state_sym, state_sym.to_s].each do |state|
        context "and passed #{state.inspect} as the state" do
          let(:data) do
            {
              state: state,
            }
          end

          it 'does not raise an error' do
            expect { event }.not_to raise_error
          end

          methods.each do |method|
            if method == state_method
              it { is_expected.to send("be_#{method}") }
            else
              it { is_expected.not_to send("be_#{method}") }
            end
          end
        end
      end
    end

    context 'and passed a state that is not a String or Symbol' do
      let(:data) do
        {
          state: %r{passed},
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{state must be a Symbol})
      end
    end

    context 'and passed an unknown state' do
      let(:data) do
        {
          state: :maybe,
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{Invalid state :maybe})
      end
    end

    context 'and passed an Integer line number' do
      let(:data) do
        {
          line: 123,
        }
      end

      it 'does not raise an error' do
        expect { event }.not_to raise_error
      end
    end

    context 'and passed a String line number containing only digits' do
      let(:data) do
        {
          line: '123',
        }
      end

      it 'does not raise an error' do
        expect { event }.not_to raise_error
      end

      it 'converts the line number to an Integer' do
        expect(event).to have_attributes(line: 123)
      end
    end

    context 'and passed a String line number containing non-digit characters' do
      let(:data) do
        {
          line: 'line 123',
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{only contain the digits 0-9})
      end
    end

    context 'and passed a line number that is not a String or Integer' do
      let(:data) do
        {
          line: [123],
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{must be an Integer or a String})
      end
    end

    context 'and passed a nil line number' do
      let(:data) do
        {
          line: nil,
        }
      end

      it 'does not raise an error' do
        expect { event }.not_to raise_error
      end

      it 'sets the line number to nil' do
        expect(event).to have_attributes(line: nil)
      end
    end

    context 'and passed an Integer column number' do
      let(:data) do
        {
          column: 456,
        }
      end

      it 'does not raise an ArgumentError' do
        expect { event }.not_to raise_error
      end
    end

    context 'and passed a String column number containing only digits' do
      let(:data) do
        {
          column: 456,
        }
      end

      it 'does not raise an error' do
        expect { event }.not_to raise_error
      end

      it 'converts the column number to an Integer' do
        expect(event).to have_attributes(column: 456)
      end
    end

    context 'and passed a String column number containing non-digit characters' do
      let(:data) do
        {
          column: 'column 456',
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{only contain the digits 0-9})
      end
    end

    context 'and passed a column number that is not a String or Integer' do
      let(:data) do
        {
          column: [456],
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{must be an Integer or a String})
      end
    end

    context 'and passed a nil column number' do
      let(:data) do
        {
          column: nil,
        }
      end

      it 'does not raise an error' do
        expect { event }.not_to raise_error
      end

      it 'sets the column number to nil' do
        expect(event).to have_attributes(column: nil)
      end
    end

    context 'and passed a trace that is not an Array' do
      let(:data) do
        {
          trace: 'test',
        }
      end

      it 'raises an ArgumentError' do
        expect { event }.to raise_error(ArgumentError, %r{trace must be an Array})
      end
    end

    context 'and passed a trace that is an Array of Strings' do
      let(:data) do
        {
          trace: [
            'lib/myfile.rb: test',
            'bin/rspec: this should not exist',
            'vendor/bundle/gems/test.rb: nor should this',
            'bin/rspec-foo: this should though',
          ],
        }
      end

      it 'does not raise an error' do
        expect { event }.not_to raise_error
      end

      it 'removes lines relating to the rspec binstub' do
        expect(event).not_to have_attributes(trace: include(a_string_matching(%r{bin/rspec:})))
      end

      it 'removes lines relating to vendored gems' do
        expect(event).not_to have_attributes(trace: include(a_string_matching(%r{/gems/})))
      end

      it 'includes the other lines' do
        expected_lines = [
          a_string_matching(%r{lib/myfile}),
          a_string_matching(%r{bin/rspec-foo}),
        ]

        expect(event).to have_attributes(trace: include(*expected_lines))
      end
    end
  end

  context 'when generating text output' do
    it 'contains the file name in the string' do
      expect(text_event).to match(%r{testfile\.rb})
    end

    context 'and a line number is provided' do
      let(:data) do
        {
          line: 123,
        }
      end

      it 'appends the line number to the file name' do
        expect(text_event).to match(%r{testfile\.rb:123})
      end

      context 'and a column number is provided' do
        let(:data) do
          {
            line:   123,
            column: 456,
          }
        end

        it 'appends the column number to the line number' do
          expect(text_event).to match(%r{testfile\.rb:123:456})
        end
      end
    end

    context 'and a severity is provided' do
      let(:data) do
        {
          severity: 'ok',
        }
      end

      it 'includes the severity at the front' do
        expect(text_event).to match(%r{\Aok:})
      end
    end

    context 'and a validator is provided' do
      let(:data) do
        {
          source: 'my-validator',
        }
      end

      it 'includes the validator' do
        expect(text_event).to match(%r{my-validator})
      end
    end

    context 'and a message is provided' do
      let(:data) do
        {
          message: 'test message',
        }
      end

      it 'includes the message at the end of the string' do
        expect(text_event).to match(%r{testfile\.rb: test message\Z})
      end

      context 'and a severity is provided' do
        let(:data) do
          {
            message:  'test message',
            severity: 'critical',
          }
        end

        it 'includes the severity before the file' do
          expect(text_event).to match(%r{\Acritical: test-validator: testfile\.rb: test message\Z})
        end
      end
    end
  end

  context 'when generating junit output' do
    it 'sets the classname attribute to the event source' do
      expect(junit_event.attributes['classname']).to eq('test-validator')
    end

    context 'and a test name is provided' do
      let(:data) do
        {
          test: 'test-method',
        }
      end

      it 'adds the test name to the classname attribute' do
        expect(junit_event.attributes['classname']).to eq('test-validator.test-method')
      end
    end

    it 'sets the testcase name to the file name' do
      expect(junit_event.attributes['name']).to eq('testfile.rb')
    end

    context 'and a line number is provided' do
      let(:data) do
        {
          line: 123,
        }
      end

      it 'adds the line number to the testcase name' do
        expect(junit_event.attributes['name']).to eq('testfile.rb:123')
      end
    end

    context 'and a column number is provided' do
      let(:data) do
        {
          column: 456,
        }
      end

      it 'adds the column number to the testcase name' do
        expect(junit_event.attributes['name']).to eq('testfile.rb:456')
      end
    end

    context 'and both line and column numbers are provided' do
      let(:data) do
        {
          line:   123,
          column: 456,
        }
      end

      it 'adds the line number and then the column number to the testcase name' do
        expect(junit_event.attributes['name']).to eq('testfile.rb:123:456')
      end
    end

    context 'for a passing test case' do
      it 'creates an xml testcase with no children' do
        expect(junit_event.children).to eq([])
      end
    end

    context 'for a skipped test case' do
      let(:data) do
        {
          state: :skipped,
        }
      end

      it 'creates an xml testcase with a "skipped" child element' do
        expect(junit_event.children.length).to eq(1)
        expect(junit_event.children.first.name).to eq('skipped')
        expect(junit_event.children.first.children).to eq([])
        expect(junit_event.children.first.attributes).to eq({})
      end
    end

    context 'for a failing test case' do
      let(:data) do
        {
          state:     :failure,
          line:      123,
          column:    456,
          severity: 'critical',
          message:  'some message',
        }
      end

      it 'creates an xml testcase with a failure child element' do
        expect(junit_event.children.length).to eq(1)
        expect(junit_event.children.first.name).to eq('failure')
      end

      it 'sets the message attribute to the message' do
        expect(junit_event.children.first.attributes['message']).to eq('some message')
      end

      it 'sets the type attribute to the severity' do
        expect(junit_event.children.first.attributes['type']).to eq('critical')
      end

      it 'puts a textual representation of the event into the failure element' do
        expect(junit_event.children.first.text).to eq(text_event)
      end
    end
  end
end
