require 'spec_helper'
require 'pdk/tests/unit'

describe 'Running `pdk test unit`' do
  subject(:test_unit_cmd) { PDK::CLI.instance_variable_get(:@test_unit_cmd) }

  it { is_expected.not_to be_nil }

  context 'with --help' do
    it do
      begin
        expect {
          PDK::CLI.run(['test', 'unit', '--help'])
        }.to output(%r{^USAGE\s+pdk test unit}m).to_stdout
      rescue SystemExit => e
        expect(e.status).to eq 0
      end
    end
  end

  context 'when listing tests' do
    let(:args) { ['--list'] }

    before(:each) do
      expect(PDK::CLI::Util).to receive(:ensure_in_module!).with(no_args).once
    end

    context 'when no tests are found' do
      before(:each) do
        expect(PDK::Test::Unit).to receive(:list).with(no_args).once.and_return([])
        expect($stdout).to receive(:puts).with(%r{No examples found})
      end

      it { test_unit_cmd.run_this(args) }
    end

    context 'when some tests are found' do
      let(:test_list) { [{ id: 'first_id', full_description: 'first_description' }, { id: 'second_id', full_description: 'second_description' }] }

      before(:each) do
        expect(PDK::Test::Unit).to receive(:list).with(no_args).once.and_return(test_list)
        expect($stdout).to receive(:puts).with('Examples:')
        expect($stdout).to receive(:puts).with(%r{first_id\tfirst_description})
        expect($stdout).to receive(:puts).with(%r{second_id\tsecond_description})
      end

      it { test_unit_cmd.run_this(args) }
    end
  end

  context 'when running tests' do
    context 'when tests pass' do
      before(:each) do
        expect(PDK::CLI::Util).to receive(:ensure_in_module!).with(no_args).once
        expect(PDK::Test::Unit).to receive(:invoke).with(instance_of(PDK::Report), hash_including(:tests)).once.and_return(0)
      end

      it 'returns 0' do
        begin
          test_unit_cmd.run_this([])
        rescue SystemExit => e
          expect(e.status).to eq 0
        end
      end
    end

    context 'when tests pass, with a format option' do
      before(:each) do
        expect(PDK::CLI::Util).to receive(:ensure_in_module!).with(no_args).once
        expect(PDK::CLI::Util::OptionNormalizer).to receive(:report_formats).with(['text:results.txt']).and_return([{ method: :write_text, target: 'results.txt' }]).twice
        expect(PDK::Test::Unit).to receive(:invoke).with(instance_of(PDK::Report), hash_including(:tests)).once.and_return(0)
      end

      it 'returns 0' do
        begin
          test_unit_cmd.run_this(['--format=text:results.txt'])
        rescue SystemExit => e
          expect(e.status).to eq 0
        end
      end
    end

    context 'when tests fail' do
      before(:each) do
        expect(PDK::CLI::Util).to receive(:ensure_in_module!).with(no_args).once
        expect(PDK::Test::Unit).to receive(:invoke).with(instance_of(PDK::Report), hash_including(:tests)).once.and_return(1)
      end

      it 'does not return 0' do
        begin
          test_unit_cmd.run_this([])
        rescue SystemExit => e
          expect(e.status).not_to eq 0
        end
      end
    end
  end
end
