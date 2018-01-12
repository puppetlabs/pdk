require 'spec_helper'
require 'pdk/tests/unit'

describe '`pdk test unit`' do
  subject(:test_unit_cmd) { PDK::CLI.instance_variable_get(:@test_unit_cmd) }

  it { is_expected.not_to be_nil }

  context 'with --help' do
    it do
      expect {
        PDK::CLI.run(['test', 'unit', '--help'])
      }.to raise_error(SystemExit) { |e|
        expect(e.status).to eq 0
      }.and output(%r{^USAGE\s+pdk test unit}m).to_stdout
    end
  end

  context 'when executing' do
    before(:each) do
      expect(PDK::CLI::Util).to receive(:ensure_in_module!).with(any_args).once
    end

    context 'when listing tests' do
      let(:args) { ['--list'] }

      context 'when no tests are found' do
        before(:each) do
          expect(PDK::Test::Unit).to receive(:list).with(no_args).once.and_return([])
        end

        it { expect { test_unit_cmd.run_this(args) }.to output(%r{No unit test files with examples were found}m).to_stdout }
      end

      context 'when some tests are found' do
        let(:test_list) do
          [{ file_path: '/path/to/first_test',
             id: 'first_id',
             full_description: 'first_description' },
           { file_path: '/path/to/second_test',
             id: 'second_id',
             full_description: 'second_description' }]
        end

        before(:each) do
          expect(PDK::Test::Unit).to receive(:list).with(no_args).once.and_return(test_list)
        end

        it { expect { test_unit_cmd.run_this(args) }.to output(%r{Unit Test Files:\n/path/to/first_test\n/path/to/second_test}m).to_stdout }
      end
    end

    context 'when listing tests with verbose' do
      let(:args) { ['--list', '-v'] }

      context 'when no tests are found' do
        before(:each) do
          expect(PDK::Test::Unit).to receive(:list).with(no_args).once.and_return([])
        end

        it { expect { test_unit_cmd.run_this(args) }.to output(%r{No unit test files with examples were found}m).to_stdout }
      end

      context 'when some tests are found' do
        let(:test_list) do
          [{ file_path: '/path/to/first_test',
             id: 'first_id',
             full_description: 'first_description' },
           { file_path: '/path/to/second_test',
             id: 'second_id',
             full_description: 'second_description' }]
        end

        before(:each) do
          expect(PDK::Test::Unit).to receive(:list).with(no_args).once.and_return(test_list)
        end

        it { expect { test_unit_cmd.run_this(args) }.to output(%r{Test Files:\n/path/to/first_test\n\tfirst_id\tfirst_description\n/path/to/second_test\n\tsecond_id\tsecond_description}m).to_stdout }
      end
    end

    context 'when running tests' do
      let(:reporter) { instance_double(PDK::Report, write_text: true) }

      before(:each) do
        allow(PDK::Report).to receive(:new).and_return(reporter)
      end

      context 'when tests pass' do
        before(:each) do
          expect(PDK::Test::Unit).to receive(:invoke).with(reporter, hash_including(:tests)).once.and_return(0)
        end

        it do
          expect {
            test_unit_cmd.run_this([])
          }.to raise_error(SystemExit) { |e|
            expect(e.status).to eq 0
          }
        end

        context 'with a format option' do
          before(:each) do
            expect(PDK::CLI::Util::OptionNormalizer).to receive(:report_formats).with(['text:results.txt']).and_return([{ method: :write_text, target: 'results.txt' }]).twice
          end

          it do
            expect {
              test_unit_cmd.run_this(['--format=text:results.txt'])
            }.to raise_error(SystemExit) { |e|
              expect(e.status).to eq 0
            }
          end
        end

        context 'with specific tests passed in' do
          let(:tests) { '/path/to/file1,/path/to/file2' }

          before(:each) do
            expect(PDK::CLI::Util::OptionValidator).to receive(:comma_separated_list?).with(tests).and_return(true)
          end

          it do
            expect {
              test_unit_cmd.run_this(["--tests=#{tests}"])
            }.to raise_error(SystemExit) { |e|
              expect(e.status).to eq 0
            }
          end
        end
      end

      context 'when tests fail' do
        before(:each) do
          expect(PDK::Test::Unit).to receive(:invoke).with(reporter, hash_including(:tests)).once.and_return(1)
        end

        it do
          expect {
            test_unit_cmd.run_this([])
          }.to raise_error(SystemExit) { |e|
            expect(e.status).not_to eq 0
          }
        end
      end
    end
  end
end
