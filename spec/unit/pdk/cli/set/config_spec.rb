require 'spec_helper'
require 'pdk/cli'

describe 'PDK::CLI::Set::Config' do
  describe '#run' do
    subject(:run) { PDK::CLI::Set::Config.run(cli_opts, cli_args) }

    let(:type_opt) { nil }
    let(:as_opt) { nil }
    let(:force_opt) { nil }
    let(:cli_opts) do
      {
        type: type_opt,
        as: as_opt,
        force: force_opt,
      }
    end
    let(:setting_name) { nil }
    let(:setting_value) { nil }
    let(:cli_args) { [setting_name, setting_value].compact }

    let(:pdk_config) { MockEmptyConfig.new }

    # Note, this class name needs to be unqiue in the ENTIRE rspec suite!
    class MockEmptyConfig < PDK::Config
      def user_config
        @user_config ||= PDK::Config::Namespace.new('user') {}
      end

      def system_config
        @system_config ||= PDK::Config::Namespace.new('system') {}
      end

      def project_config
        @project_config ||= PDK::Config::Namespace.new('project') {}
      end
    end

    before(:each) do
      allow(PDK).to receive(:config).and_return(pdk_config)
      allow($stdout).to receive(:puts)
    end

    RSpec.shared_examples 'a missing name error' do
      it 'raises with missing name' do
        expect { run }.to raise_error(PDK::CLI::ExitWithError, %r{name is required})
      end
    end

    RSpec.shared_examples 'a missing value error' do
      it 'raises with missing value' do
        expect { run }.to raise_error(PDK::CLI::ExitWithError, %r{value is required})
      end
    end

    RSpec.shared_examples 'a failed conversion error' do
      it 'raises with failed conversion' do
        expect { run }.to raise_error(PDK::CLI::ExitWithError, %r{error occured converting .* into a .*})
      end
    end

    RSpec.shared_examples 'a un-settable setting error' do
      it 'raises with failed conversion' do
        expect { run }.to raise_error(PDK::CLI::ExitWithError, %r{can not have a value set})
      end
    end

    RSpec.shared_examples 'a saved setting' do |setting_name, expected_value, force = nil|
      it 'saves the setting' do
        expect(pdk_config).to receive(:set).with(setting_name, anything, force: force).and_call_original
        expect(run).to eq(0)
        expect(pdk_config.get(setting_name)).to eq(expected_value)
      end
    end

    context 'with no arguments or flags' do
      it_behaves_like 'a missing name error'
    end

    context 'with a missing value and no type information' do
      let(:setting_name) { 'user' }

      it_behaves_like 'a missing value error'
    end

    context 'with a missing value and non-array type information' do
      let(:setting_name) { 'user' }

      PDK::CLI::Set::Config::ALLOWED_TYPE_NAMES.reject { |i| i == 'array' }.each do |type_name|
        context "with type #{type_name}" do
          let(:type_opt) { type_name }

          it_behaves_like 'a failed conversion error'
        end
      end
    end

    context 'with bad a type conversion' do
      let(:setting_name) { 'user.foo' }
      let(:setting_value) { 'i_am_not_a_number' }
      let(:type_opt) { 'number' }

      it_behaves_like 'a failed conversion error'
    end

    context 'with a setting name that is a root namespace' do
      let(:setting_name) { 'user' }
      let(:setting_value) { 'foo' }

      it_behaves_like 'a un-settable setting error'
    end

    context 'using --as instead of --type' do
      let(:setting_name) { 'user.foo' }
      let(:as_opt) { 'number' }
      let(:setting_value) { 1 }

      it_behaves_like 'a saved setting', 'user.foo', 1, nil
    end

    context 'with a missing value and array type information' do
      let(:setting_name) { 'user.foo' }
      let(:type_opt) { 'array' }

      it_behaves_like 'a saved setting', 'user.foo', []
    end

    context 'when appending a value to an existing array' do
      let(:setting_name) { 'user.foo' }

      before(:each) do
        pdk_config.user_config['foo'] = []
      end

      context 'and the value is an array' do
        let(:type_opt) { 'array' }
        let(:setting_value) { 'nested' }

        it_behaves_like 'a saved setting', 'user.foo', [['nested']]
      end

      context 'and the value is a boolan' do
        let(:type_opt) { 'boolean' }
        let(:setting_value) { 'Yes' }

        it_behaves_like 'a saved setting', 'user.foo', [true]
      end

      context 'and the value is a number' do
        let(:type_opt) { 'number' }
        let(:setting_value) { '1.0' }

        it_behaves_like 'a saved setting', 'user.foo', [1.0]
      end

      context 'and the value is a string' do
        let(:type_opt) { 'string' }
        let(:setting_value) { 'new_value' }

        it_behaves_like 'a saved setting', 'user.foo', ['new_value']
      end
    end

    context 'when appending a value that already exists to an existing array' do
      let(:setting_name) { 'user.foo' }
      let(:setting_value) { 'abc' }

      before(:each) do
        pdk_config.user_config['foo'] = ['abc', 123]
      end

      it 'does not save the setting' do
        expect(pdk_config).not_to receive(:set)
        expect(run).to eq(0)
        expect(pdk_config.get(setting_name)).to eq(['abc', 123])
      end

      it 'logs an information message' do
        expect(PDK.logger).to receive(:info).with(%r{No changes made .+ already contains value}im)
        run
      end

      context 'and force is set' do
        let(:force_opt) { true }

        it_behaves_like 'a saved setting', 'user.foo', 'abc', true
      end
    end

    context 'when creating a deep hash' do
      let(:setting_name) { 'user.foo.a.b.c' }
      let(:setting_value) { 'abc' }

      before(:each) do
        pdk_config.user_config['foo'] = { 'bar' => 'whizz' }
      end

      it_behaves_like 'a saved setting', 'user.foo.a.b.c', 'abc'

      it 'merges the value into the hash' do
        expect(run).to eq(0)
        expect(pdk_config.get('user.foo')).to eq('a' => { 'b' => { 'c' => 'abc' } }, 'bar' => 'whizz')
      end
    end
  end

  describe '#transform_value' do
    let(:type_name) { nil }
    let(:value) { nil }

    RSpec.shared_examples 'a value transformer' do |value, expected|
      it "converts valid value '#{value}' to a #{expected.class.name}" do
        result = PDK::CLI::Set::Config.transform_value(type_name, value)
        expect(result.class.name).to eq(expected.class.name)
        expect(result).to eq(expected)
      end
    end

    RSpec.shared_examples 'a value transformer error' do |value|
      it "raises with invalid value '#{value}'" do
        expect { PDK::CLI::Set::Config.transform_value(type_name, value) }.to raise_error(PDK::CLI::ExitWithError)
      end
    end

    context 'given a type of array' do
      let(:type_name) { 'array' }

      it_behaves_like 'a value transformer', 'abc', ['abc']
      it_behaves_like 'a value transformer', nil, []
      it_behaves_like 'a value transformer', [123], [123]
      it_behaves_like 'a value transformer', { 'abc' => 123 }, [{ 'abc' => 123 }]
      it_behaves_like 'a value transformer', 1, [1]
    end

    context 'given a type of boolean' do
      let(:type_name) { 'boolean' }

      it_behaves_like 'a value transformer error', 'abc'
      it_behaves_like 'a value transformer error', '1.0a'
      it_behaves_like 'a value transformer error', nil
      it_behaves_like 'a value transformer error', [123]
      it_behaves_like 'a value transformer error', 'abc' => 123

      it_behaves_like 'a value transformer', 'YES', true
      it_behaves_like 'a value transformer', 'yEs', true
      it_behaves_like 'a value transformer', '-1', true
      it_behaves_like 'a value transformer', 'true', true
      it_behaves_like 'a value transformer', 'True', true
      it_behaves_like 'a value transformer', 'NO', false
      it_behaves_like 'a value transformer', 'nO', false
      it_behaves_like 'a value transformer', '0', false
      it_behaves_like 'a value transformer', 'false', false
      it_behaves_like 'a value transformer', 'FALSE', false
    end

    context 'given a type of number' do
      let(:type_name) { 'number' }

      it_behaves_like 'a value transformer error', 'abc'
      it_behaves_like 'a value transformer error', '1.0a'
      it_behaves_like 'a value transformer error', nil
      it_behaves_like 'a value transformer error', [123]
      it_behaves_like 'a value transformer error', 'abc' => 123

      it_behaves_like 'a value transformer', '1', Integer('1')
      it_behaves_like 'a value transformer', '1.0', Integer('1')
      it_behaves_like 'a value transformer', '1.1', Float('1.1')
      it_behaves_like 'a value transformer', '-1.1', Float('-1.1')
    end

    context 'given a type of string' do
      let(:type_name) { 'string' }

      it_behaves_like 'a value transformer error', nil
      it_behaves_like 'a value transformer error', [123]
      it_behaves_like 'a value transformer error', 'abc' => 123

      it_behaves_like 'a value transformer', '1', '1'
      it_behaves_like 'a value transformer', '1.0', '1.0'
      it_behaves_like 'a value transformer', 'abc123', 'abc123'
    end
  end
end
