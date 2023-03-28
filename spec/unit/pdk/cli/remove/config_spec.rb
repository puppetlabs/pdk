require 'spec_helper'
require 'pdk/cli'

describe 'PDK::CLI::Remove::Config' do
  describe '#run' do
    subject(:run) { PDK::CLI::Remove::Config.run(cli_opts, cli_args) }

    let(:force_opt) { nil }
    let(:cli_opts) do
      {
        force: force_opt,
      }
    end
    let(:setting_name) { nil }
    let(:setting_value) { nil }
    let(:cli_args) { [setting_name, setting_value].compact }

    let(:pdk_config) { MockRemoveConfig.new }

    SETTING_ARRAY_NONDEFAULT = 'user.array_nondefault'.freeze
    SETTING_ARRAY_DEFAULT = 'user.array_default'.freeze
    SETTING_NUMBER_NONDEFAULT = 'user.number_nondefault'.freeze
    SETTING_NUMBER_DEFAULT = 'user.number_default'.freeze
    SETTING_STRING_NONDEFAULT = 'user.string_nondefault'.freeze
    SETTING_STRING_DEFAULT = 'user.string_default'.freeze
    SETTING_HASH_NONDEFAULT = 'user.hash_nondefault'.freeze
    SETTING_HASH_DEFAULT = 'user.hash_default'.freeze
    SETTING_DEEPHASH_DEFAULT = 'user.hash_default.default.foo'.freeze
    VALUE_ARRAY_DEFAULT = ['1', '2', '3', 1, 2, 3].freeze
    VALUE_NUMBER_DEFAULT = 3
    VALUE_STRING_DEFAULT = 'default'.freeze
    VALUE_HASH_DEFAULT = { 'default' => { 'foo' => { 'bar' => 'baz' } } }.freeze

    # Note, this class name needs to be unqiue in the ENTIRE rspec suite!
    class MockRemoveConfig < PDK::Config
      def user_config
        @user_config ||= PDK::Config::Namespace.new('user') do
          setting 'array_default' do
            default_to do
              VALUE_ARRAY_DEFAULT
            end
          end

          setting 'string_default' do
            default_to do
              VALUE_STRING_DEFAULT
            end
          end

          setting 'number_default' do
            default_to do
              VALUE_NUMBER_DEFAULT
            end
          end

          setting 'hash_default' do
            default_to do
              VALUE_HASH_DEFAULT
            end
          end
        end
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

      pdk_config.set(SETTING_STRING_NONDEFAULT, 'non-default', force: true)
      pdk_config.set(SETTING_NUMBER_NONDEFAULT, -1000, force: true)
      pdk_config.set(SETTING_ARRAY_NONDEFAULT, ['non-default', -6000], force: true)
      pdk_config.set(SETTING_HASH_NONDEFAULT, { 'non-default' => { 'bar' => 'baz' } }, force: true)
    end

    RSpec.shared_examples 'a missing name error' do
      it 'raises with missing name' do
        expect { run }.to raise_error(PDK::CLI::ExitWithError, %r{name is required})
      end
    end

    RSpec.shared_examples 'an un-removable setting error' do
      it 'raises with can not be removed' do
        expect { run }.to raise_error(PDK::CLI::ExitWithError, %r{can not be removed})
      end
    end

    RSpec.shared_examples 'a removed setting' do |setting_under_test, expected_value, log_msg_regex|
      let(:setting_name) { setting_under_test }

      it 'removes the setting' do
        # Ensure that the value is different than what we want to set it to
        expect(pdk_config.get(setting_name)).not_to eq(expected_value)
        # Ensure that the config.set method is actually called for the setting we are changing
        expect(pdk_config).to receive(:set).with(setting_name, anything, force: true).and_call_original
        # This is default log message regex, typically for strings and numbers.  Arrays
        # are complex so the actual test can set the required regex
        log_msg_regex = %r{Removed .+ which had a value of} if log_msg_regex.nil?
        expect(PDK.logger).to receive(:info).with(log_msg_regex)

        expect(run).to eq(0)
        expect(pdk_config.get(setting_name)).to eq(expected_value)
      end
    end

    RSpec.shared_examples 'a removed setting with a default' do |setting_under_test, initial_value, expected_default_value|
      let(:setting_name) { setting_under_test }

      before(:each) do
        pdk_config.set(setting_name, initial_value)
      end

      it 'resets back to default' do
        # Ensure that the config.set method is actually called for the setting we are changing
        expect(pdk_config).to receive(:set).with(setting_name, anything, force: true).and_call_original
        # Ensure that a log message occurs to state that this is now using the default value
        expect(PDK.logger).to receive(:info).with(%r{as it using a default value of})
        # Ensure that the value is different than what we want to set it to
        expect(pdk_config.get(setting_name)).not_to eq(expected_default_value)
        expect(run).to eq(0)
        expect(pdk_config.get(setting_name)).to eq(expected_default_value)
      end
    end

    RSpec.shared_examples 'a setting which cannot be forced' do |setting_under_test|
      let(:setting_name) { setting_under_test }
      let(:force_opt) { true }

      it 'logs a message that --force is ignored' do
        expect(PDK.logger).to receive(:info).with(%r{Ignoring --force as the})
        run
      end
    end

    context 'with no arguments or flags' do
      include_examples 'a missing name error'
    end

    context 'with a setting name that is a root namespace' do
      let(:setting_name) { 'user' }

      include_examples 'an un-removable setting error'
    end

    context 'when removing a string type setting' do
      it_behaves_like 'a removed setting', SETTING_STRING_NONDEFAULT, nil
      it_behaves_like 'a removed setting with a default', SETTING_STRING_DEFAULT, 'koala', VALUE_STRING_DEFAULT
      it_behaves_like 'a setting which cannot be forced', SETTING_STRING_DEFAULT
    end

    context 'when removing a number type setting' do
      it_behaves_like 'a removed setting', SETTING_NUMBER_NONDEFAULT, nil
      it_behaves_like 'a removed setting with a default', SETTING_NUMBER_DEFAULT, -6000, VALUE_NUMBER_DEFAULT
      it_behaves_like 'a setting which cannot be forced', SETTING_NUMBER_NONDEFAULT
    end

    context 'when removing a hash type setting' do
      it_behaves_like 'a removed setting', SETTING_HASH_NONDEFAULT, nil
      it_behaves_like 'a removed setting with a default', SETTING_HASH_DEFAULT, { 'something' => 'value' }, VALUE_HASH_DEFAULT
      it_behaves_like 'a setting which cannot be forced', SETTING_HASH_NONDEFAULT
    end

    context 'when removing a deep hash type setting' do
      let(:setting_name) { SETTING_DEEPHASH_DEFAULT }

      it_behaves_like 'a removed setting', SETTING_DEEPHASH_DEFAULT, nil

      it 'only removes the the setting and and any child values' do
        expected_value = { 'default' => { 'foo' => nil } }
        expect(pdk_config.get(SETTING_HASH_DEFAULT)).not_to eq(expected_value)
        run
        expect(pdk_config.get(SETTING_HASH_DEFAULT)).to eq(expected_value)
      end
    end

    context 'when removing an array type setting' do
      context 'without --force' do
        context 'without an item value' do
          it_behaves_like 'a removed setting', SETTING_ARRAY_NONDEFAULT, [], %r{Cleared .+ which had a value of}
          # An empty array does not use the default value, only an undefined (or nil)
          # setting will trigger the default
          context 'which has a default value' do
            include_examples 'a removed setting', SETTING_ARRAY_DEFAULT, [], %r{Cleared .+ which had a value of}
          end
        end

        context 'with an item value which removes the last array item' do
          let(:setting_value) { 'quokka' }

          before(:each) do
            pdk_config.set(setting_name, ['quokka'], force: true)
          end

          it_behaves_like 'a removed setting', SETTING_ARRAY_NONDEFAULT, [], %r{Removed .+ from .+}
          # An empty array does not use the default value, only an undefined (or nil)
          # setting will trigger the default
          context 'which has a default value' do
            include_examples 'a removed setting', SETTING_ARRAY_DEFAULT, [], %r{Removed .+ from .+}
          end
        end

        context 'with an item value which removes the second last array item' do
          let(:setting_value) { 'quokka' }

          before(:each) do
            pdk_config.set(setting_name, ['quokka', 'kangaroo'], force: true)
          end

          it_behaves_like 'a removed setting', SETTING_ARRAY_NONDEFAULT, ['kangaroo'], %r{Removed .+ from .+}
          # An empty array does not use the default value, only an undefined (or nil)
          # setting will trigger the default
          context 'which has a default value' do
            include_examples 'a removed setting', SETTING_ARRAY_DEFAULT, ['kangaroo'], %r{Removed .+ from .+}
          end
        end
      end

      context 'with --force' do
        let(:force_opt) { true }

        context 'without an item value' do
          it_behaves_like 'a removed setting', SETTING_ARRAY_NONDEFAULT, nil
          it_behaves_like 'a removed setting with a default', SETTING_ARRAY_DEFAULT, ['koala'], VALUE_ARRAY_DEFAULT
        end

        context 'with an item value which removes the last array item' do
          # Using a setting_value with --force doesn't make much sense, so
          # the setting_value is just ignored.
          let(:setting_value) { 'quokka' }

          before(:each) do
            pdk_config.set(setting_name, ['quokka'], force: true)
            expect(PDK.logger).to receive(:info).with(%r{Ignoring the item value .+ as --force has been set})
          end

          it_behaves_like 'a removed setting', SETTING_ARRAY_NONDEFAULT, nil
          it_behaves_like 'a removed setting with a default', SETTING_ARRAY_DEFAULT, ['koala'], VALUE_ARRAY_DEFAULT
        end

        context 'with an item value which removes the second last array item' do
          let(:setting_value) { 'quokka' }

          before(:each) do
            pdk_config.set(setting_name, ['quokka', 'kangaroo'], force: true)
            expect(PDK.logger).to receive(:info).with(%r{Ignoring the item value .+ as --force has been set})
          end

          it_behaves_like 'a removed setting', SETTING_ARRAY_NONDEFAULT, nil
          it_behaves_like 'a removed setting with a default', SETTING_ARRAY_DEFAULT, ['koala'], VALUE_ARRAY_DEFAULT
        end
      end
    end
  end
end
