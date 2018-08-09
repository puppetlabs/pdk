require 'spec_helper'
require 'pdk/tests/unit'

describe '`pdk test unit`' do
  subject(:test_unit_cmd) { PDK::CLI.instance_variable_get(:@test_unit_cmd) }

  it { is_expected.not_to be_nil }

  before(:each) do
    allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env).and_return(ruby_version: '2.4.3', gemset: { puppet: '5.4.0' })
    allow(PDK::Util::RubyVersion).to receive(:use)
    allow(PDK::Util::Bundler).to receive(:ensure_bundle!).with(hash_including(:puppet))
  end

  context 'with --help' do
    it do
      expect { PDK::CLI.run(['test', 'unit', '--help']) }.to exit_zero.and output(%r{^USAGE\s+pdk test unit}m).to_stdout
    end
  end

  context 'when executing' do
    before(:each) do
      expect(PDK::CLI::Util).to receive(:ensure_in_module!).with(any_args).once
      expect(PDK::Util).to receive(:module_pdk_version).and_return(PDK::VERSION)
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

      context 'when passed --clean-fixtures' do
        it 'invokes the command with :clean-fixtures => true' do
          expect(PDK::Test::Unit).to receive(:invoke).with(reporter, :tests => anything, :'clean-fixtures' => true).once.and_return(0)
          expect {
            test_unit_cmd.run_this(['--clean-fixtures'])
          }.to exit_zero
        end
      end

      context 'when not passed --clean-fixtures' do
        it 'invokes the command without :clean-fixtures' do
          expect(PDK::Test::Unit).to receive(:invoke).with(reporter, tests: anything).once.and_return(0)
          expect {
            test_unit_cmd.run_this([])
          }.to exit_zero
        end
      end
      context 'when tests pass' do
        before(:each) do
          expect(PDK::Test::Unit).to receive(:invoke).with(reporter, hash_including(:tests)).once.and_return(0)
        end

        it do
          expect { test_unit_cmd.run_this([]) }.to exit_zero
        end

        context 'with a format option' do
          before(:each) do
            expect(PDK::CLI::Util::OptionNormalizer).to receive(:report_formats).with(['text:results.txt']).and_return([{ method: :write_text, target: 'results.txt' }]).twice
          end

          it do
            expect { test_unit_cmd.run_this(['--format=text:results.txt']) }.to exit_zero
          end
        end

        context 'with specific tests passed in' do
          let(:tests) { '/path/to/file1,/path/to/file2' }

          before(:each) do
            expect(PDK::CLI::Util::OptionValidator).to receive(:comma_separated_list?).with(tests).and_return(true)
          end

          it do
            expect { test_unit_cmd.run_this(["--tests=#{tests}"]) }.to exit_zero
          end
        end
      end

      context 'when tests fail' do
        before(:each) do
          expect(PDK::Test::Unit).to receive(:invoke).with(reporter, hash_including(:tests)).once.and_return(1)
        end

        it do
          expect { test_unit_cmd.run_this([]) }.to exit_nonzero
        end
      end
    end
  end

  context 'with --puppet-dev' do
    let(:puppet_env) do
      {
        ruby_version: '2.4.3',
        gemset: { puppet: 'file://path/to/puppet' },
      }
    end

    before(:each) do
      allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env).with(hash_including(:'puppet-dev' => true)).and_return(puppet_env)
      allow(PDK::Util::PuppetVersion).to receive(:fetch_puppet_dev).and_return(nil)
      allow(PDK::Test::Unit).to receive(:invoke).and_return(0)
      allow(PDK::CLI::Util).to receive(:module_version_check)
    end

    it 'activates puppet github source' do
      expect(PDK::Util::Bundler).to receive(:ensure_bundle!).with(puppet_env[:gemset])

      expect {
        test_unit_cmd.run_this(['--puppet-dev'])
      }.to exit_zero
    end

    it 'activates resolved ruby version' do
      expect(PDK::Util::RubyVersion).to receive(:use).with(puppet_env[:ruby_version])

      expect {
        test_unit_cmd.run_this(['--puppet-dev'])
      }.to exit_zero
    end
  end

  context 'when --puppet-version and --pe-version are specified' do
    it 'exits with an error' do
      expect(logger).to receive(:error).with(a_string_matching(%r{cannot specify.*--pe-version.*and.*--puppet-version}i))

      expect {
        PDK::CLI.run(%w[test unit --puppet-version 4.10.10 --pe-version 2018.1.1])
      }.to exit_nonzero
    end
  end

  context 'with --puppet-version' do
    let(:puppet_version) { '5.3' }
    let(:puppet_env) do
      {
        ruby_version: '2.4.3',
        gemset: { puppet: '5.3.5' },
      }
    end

    before(:each) do
      allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env).with(hash_including(:'puppet-version' => puppet_version)).and_return(puppet_env)
      allow(PDK::Test::Unit).to receive(:invoke).and_return(0)
      allow(PDK::CLI::Util).to receive(:module_version_check)
    end

    it 'activates resolved puppet version' do
      expect(PDK::Util::Bundler).to receive(:ensure_bundle!).with(puppet_env[:gemset])

      expect {
        test_unit_cmd.run_this(["--puppet-version=#{puppet_version}"])
      }.to exit_zero
    end

    it 'activates resolved ruby version' do
      expect(PDK::Util::RubyVersion).to receive(:use).with(puppet_env[:ruby_version])

      expect {
        test_unit_cmd.run_this(["--puppet-version=#{puppet_version}"])
      }.to exit_zero
    end
  end

  context 'with --pe-version' do
    let(:pe_version) { '2017.2' }
    let(:puppet_env) do
      {
        ruby_version: '2.1.9',
        gemset: { puppet: '4.10.9' },
      }
    end

    before(:each) do
      allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env).with(hash_including(:'pe-version' => pe_version)).and_return(puppet_env)
      allow(PDK::Test::Unit).to receive(:invoke).and_return(0)
      allow(PDK::CLI::Util).to receive(:module_version_check)
    end

    it 'activates resolved puppet version' do
      expect(PDK::Util::Bundler).to receive(:ensure_bundle!).with(puppet_env[:gemset])

      expect {
        test_unit_cmd.run_this(["--pe-version=#{pe_version}"])
      }.to exit_zero
    end

    it 'activates resolved ruby version' do
      expect(PDK::Util::RubyVersion).to receive(:use).with(puppet_env[:ruby_version])

      expect {
        test_unit_cmd.run_this(["--pe-version=#{pe_version}"])
      }.to exit_zero
    end
  end
end
