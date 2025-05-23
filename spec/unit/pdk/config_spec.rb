require 'spec_helper'
require 'securerandom'
require 'tty/prompt/test'
require 'pdk/config'

describe PDK::Config do
  subject(:config) { described_class.new }

  include_context 'mock configuration'

  def mock_file(path, content)
    allow(PDK::Util::Filesystem).to receive(:file?).with(PDK::Util::Filesystem.expand_path(path)).and_return(true)
    allow(PDK::Util::Filesystem).to receive(:write_file).with(PDK::Util::Filesystem.expand_path(path), anything)
    allow(PDK::Util::Filesystem).to receive(:read_file).with(PDK::Util::Filesystem.expand_path(path)).and_return(content)
  end

  before do
    allow(PDK::Util::Filesystem).to receive(:file?).with(/pdk\.yaml/).and_call_original
    # Allow the JSON Schema documents to actually be read. Rspec matchers are LIFO
    allow(PDK::Util::Filesystem).to receive(:file?).with(/_schema\.json/).and_call_original
  end

  describe '.system_config' do
    it 'returns a PDK::Config::Namespace' do
      expect(config.system_config).to be_a(described_class::Namespace)
    end
  end

  describe '.user_config' do
    it 'returns a PDK::Config::Namespace' do
      expect(config.user_config).to be_a(described_class::Namespace)
    end
  end

  describe '.project_config' do
    it 'returns a PDK::Config::Namespace' do
      expect(config.project_config).to be_a(described_class::Namespace)
    end

    context 'Given a Control Repo context' do
      subject(:config) { described_class.new('context' => repo_context) }

      let(:repo_path) { File.join(FIXTURES_DIR, 'control_repo') }
      let(:repo_context) { PDK::Context::ControlRepo.new(repo_path, repo_path) }

      before do
        # Allow anything in the fixtures dir to actually be read
        allow(PDK::Util::Filesystem).to receive(:file?).with(/#{FIXTURES_DIR}/o).and_call_original
        allow(PDK::Util::Filesystem).to receive(:read_file).with(/#{FIXTURES_DIR}/o).and_call_original
      end

      it 'has environment settings' do
        # The modulepath has a default setting so it will always exist
        expect(config.get('project.environment.modulepath')).not_to be_nil
      end
    end
  end

  describe '.resolve' do
    subject(:resolve) { config.resolve(filter) }

    let(:filter) { nil }

    context 'given no filter' do
      let(:filter) { nil }
      let(:user_config_content) { '{ "setting": "user_setting_value" }' }
      let(:system_config_content) { '{ "setting": "system_setting_value" }' }

      it 'returns settings at user and system level' do
        result = resolve

        expect(result['user.setting']).to eq('user_setting_value')
        expect(result['system.setting']).to eq('system_setting_value')
      end
    end
  end

  describe '.get' do
    let(:system_config_content) do
      <<-EOT
      {
        "setting": {
          "child": {
            "child_setting": "child_setting_value"
          }
        }
      }
      EOT
    end

    it 'returns nil for invalid names' do
      [nil, { 'a' => 'Hash' }, []].each do |testcase|
        expect(config.get(testcase)).to be_nil
      end
    end

    context 'given different setting name types' do
      it 'uses multiple parameters for the setting name' do
        setting_name = ['system', 'setting', 'child', 'child_setting']
        expect(config.get(*setting_name)).to eq('child_setting_value')
      end

      it 'uses an Array for the setting name' do
        setting_name = ['system', 'setting', 'child', 'child_setting']
        expect(config.get(setting_name)).to eq('child_setting_value')
      end

      it 'uses a String for the setting name' do
        setting_name = 'system.setting.child.child_setting'
        expect(config.get(setting_name)).to eq('child_setting_value')
      end
    end

    it 'traverses root names' do
      expect(config.get('user')).to be_a(described_class::Namespace)
    end

    # Test previously work due to the boolean value `user.analytics.disabled` always being present
    # it 'traverses namespaces' do
    #   expect(config.get('user', 'module_defaults', 'author')).to eq(['controlrepo'])
    # end

    it 'traverses setting hash values' do
      expect(config.get('system', 'setting', 'child', 'child_setting')).to eq('child_setting_value')
    end

    it 'returns isolated objects' do
      current_value = config.get('system', 'setting', 'child')
      current_value['foo'] = 'bar'
      expect(config.get('system', 'setting', 'child', 'child_setting')).to eq('child_setting_value')
      # The setting in the current_value hash should not be present in config.get
      expect(config.get('system', 'setting', 'child', 'foo')).to be_nil
    end

    context 'given a setting name that does not exist' do
      let(:names) { ['system', 'setting', 'missing_child', 'child_setting'] }

      it 'returns nil' do
        expect(config.get(*names)).to be_nil
      end
    end

    context 'given a root name that does not exist' do
      let(:names) { ['missing', 'module_defaults', 'author'] }

      it 'returns nil' do
        expect(config.get(*names)).to be_nil
      end
    end
  end

  describe '.get_within_scopes' do
    subject(:setting_value) { config.get_within_scopes(setting_name, scopes) }

    let(:scopes) { nil }
    let(:setting_name) { 'name' }
    let(:user_value) { 'user' }
    let(:system_value) { 'system' }

    context 'with invalid arguments' do
      context 'with scopes argument of String' do
        let(:scopes) { 'scope' }

        it 'raises ArgumentError' do
          expect { setting_value }.to raise_error(ArgumentError)
        end
      end

      context 'with setting_name argument of nil' do
        let(:setting_name) { nil }

        it 'raises ArgumentError' do
          expect { setting_value }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with different setting_name inputs' do
      let(:setting_name_as_string) { 'foo.bar.baz' }
      let(:setting_name_as_array) { ['foo', 'bar', 'baz'] }

      let(:user_value) { 'something' }
      let(:user_config_content) { "{\"foo\":{\"bar\":{\"baz\":\"#{user_value}\"}}}" }

      it 'uses a string' do
        expect(config.get_within_scopes(setting_name_as_string)).to eq(user_value)
      end

      it 'uses an array' do
        expect(config.get_within_scopes(setting_name_as_array)).to eq(user_value)
      end
    end

    shared_examples 'a setting resolver' do |nil_nil_value, user_nil_value, nil_system_value, user_system_value|
      context 'given a setting that does not appear in either user or system level' do
        it "returns #{nil_nil_value.nil? ? 'nil' : nil_nil_value}" do
          expect(setting_value).to eq(nil_nil_value)
        end
      end

      context 'given a setting that appears at the user level but not the system' do
        let(:user_config_content) { " { \"#{setting_name}\": \"#{user_value}\"}" }

        it "returns #{user_nil_value.nil? ? 'nil' : user_nil_value}" do
          expect(setting_value).to eq(user_nil_value)
        end
      end

      context 'given a setting that appears at the system level but not the user' do
        let(:system_config_content) { " { \"#{setting_name}\": \"#{system_value}\"}" }

        it "returns #{nil_system_value.nil? ? 'nil' : nil_system_value}" do
          expect(setting_value).to eq(nil_system_value)
        end
      end

      context 'given a setting that appears in both user and system level' do
        let(:user_config_content) { " { \"#{setting_name}\": \"#{user_value}\"}" }
        let(:system_config_content) { " { \"#{setting_name}\": \"#{system_value}\"}" }

        it "returns #{user_system_value.nil? ? 'nil' : user_system_value}" do
          expect(setting_value).to eq(user_system_value)
        end
      end
    end

    context 'given no scopes' do
      let(:scopes) { nil }

      it_behaves_like 'a setting resolver', nil, 'user', 'system', 'user'
    end

    context 'given only a scope that does not exist' do
      let(:scopes) { ['does_not_exist'] }

      it_behaves_like 'a setting resolver', nil, nil, nil, nil
    end

    context 'given empty scopes' do
      let(:scopes) { [] }

      it_behaves_like 'a setting resolver', nil, nil, nil, nil
    end

    context 'given both user and system scopes' do
      let(:scopes) { ['user', 'system'] }

      it_behaves_like 'a setting resolver', nil, 'user', 'system', 'user'
    end

    context 'given user, system and non-existent scopes' do
      let(:scopes) { ['user', 'does_not_exist', 'system'] }

      it_behaves_like 'a setting resolver', nil, 'user', 'system', 'user'
    end

    context 'given only a system scope' do
      let(:scopes) { ['system'] }

      it_behaves_like 'a setting resolver', nil, nil, 'system', 'system'
    end

    context 'given system and then user scopes (non-default order)' do
      let(:scopes) { ['system', 'user'] }

      it_behaves_like 'a setting resolver', nil, 'user', 'system', 'system'
    end
  end

  describe '.with_scoped_value' do
    let(:scopes) { nil }
    let(:setting_name) { 'name' }
    let(:setting_value) { 'user' }
    let(:user_config_content) { "{\"#{setting_name}\":\"#{setting_value}\"}" }

    it 'yields the value if it exists' do
      expect { |val| config.with_scoped_value(setting_name, scopes, &val) }.to yield_with_args(setting_value)
    end

    it 'does not yield if the setting does not exist' do
      expect { |val| config.with_scoped_value('missing', scopes, &val) }.not_to yield_control
    end

    it 'raises if no block is passed' do
      expect { config.with_scoped_value(setting_name, scopes) }.to raise_error(ArgumentError)
    end
  end

  describe '.set' do
    # Note, this class name needs to be unqiue in the ENTIRE rspec suite!
    class MockUserOnlyConfig < PDK::Config
      def user_config
        @user_config ||= PDK::Config::JSON.new('user', file: 'path/does/not/exist/root.json') do
          mount :foo, PDK::Config::JSON.new(file: 'path/does/not/exist/foo.json') do
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

    subject(:config) { MockUserOnlyConfig.new }

    let(:value) { 'mock_value' }
    let(:root_file) { 'path/does/not/exist/root.json' }
    let(:root_file_content) { '{}' }
    let(:foo_file) { 'path/does/not/exist/foo.json' }
    let(:foo_file_content) { '{}' }
    let(:set_options) { {} }

    before do
      mock_file(root_file, root_file_content)
      mock_file(foo_file, foo_file_content)
      allow(PDK::Util::Filesystem).to receive(:mkdir_p).with(anything)
    end

    shared_examples 'a round-tripped setting' do
      it 'round-trips the setting value' do
        # First make sure the setting doesn't exist
        expect(config.get(*setting)).to be_nil
        # Set the setting
        expect(config.set(setting, value)).to eq(value)
        # Get the new value
        expect(config.get(*setting)).to eq(value)
      end
    end

    shared_examples 'a new setting file' do |new_content|
      it 'does not save to the root file' do
        expect(PDK::Util::Filesystem).not_to receive(:write_file).with(PDK::Util::Filesystem.expand_path(root_file), anything)
        config.set(setting, value, set_options)
      end

      it 'saves to the nested file' do
        expect(PDK::Util::Filesystem).to receive(:write_file).with(PDK::Util::Filesystem.expand_path(foo_file), new_content)
        config.set(setting, value, set_options)
      end
    end

    it 'raises an error for invalid names' do
      [nil, { 'a' => 'Hash' }, []].each do |testcase|
        expect { config.set(testcase, value) }.to raise_error(ArgumentError)
      end
    end

    it 'takes a String for the setting name' do
      config.set('user.foo.whizz', value)
      expect(config.get('user.foo.whizz')).to eq(value)
    end

    it 'takes an Array for the setting name' do
      config.set(['user', 'foo', 'whizz'], value)
      expect(config.get(['user', 'foo', 'whizz'])).to eq(value)
    end

    context 'given a root name that does not exist' do
      let(:names) { ['missing', 'module_defaults', 'author'] }

      it 'raises an error' do
        expect { config.set(names, value) }.to raise_error(ArgumentError)
      end
    end

    it 'raises an error when setting a value to a namespace mount' do
      expect { config.set(['user', 'foo'], value) }.to raise_error(ArgumentError)
    end

    context 'given a plain root setting' do
      let(:setting) { ['user', 'setting'] }

      it_behaves_like 'a round-tripped setting'
    end

    context 'given a plain nested setting' do
      let(:setting) { ['user', 'foo', 'setting'] }

      it_behaves_like 'a round-tripped setting'
    end

    context 'given a hash root setting that doesn\'t already exist' do
      let(:setting) { ['user', 'bar', 'baz', 'setting'] }
      let(:new_file_content) { "{\n  \"bar\": {\n    \"baz\": {\n      \"setting\": \"mock_value\"\n    }\n  }\n}" }

      it_behaves_like 'a round-tripped setting'

      it 'can be accessed via a normal hash syntax' do
        config.set(setting, value)

        expect(config.get(['user', 'bar', 'baz', 'setting'])).to eq(value)
      end

      it 'saves to the root file' do
        expect(PDK::Util::Filesystem).to receive(:write_file).with(PDK::Util::Filesystem.expand_path(root_file), new_file_content)
        config.set(setting, value)
      end

      it 'does not save to the nested file' do
        expect(PDK::Util::Filesystem).not_to receive(:write_file).with(PDK::Util::Filesystem.expand_path(foo_file), anything)
        config.set(setting, value)
      end
    end

    context 'given a hash nested setting that doesn\'t already exist' do
      let(:setting) { ['user', 'foo', 'bar', 'baz', 'setting'] }
      let(:new_file_content) { "{\n  \"bar\": {\n    \"baz\": {\n      \"setting\": \"mock_value\"\n    }\n  }\n}" }

      it_behaves_like 'a round-tripped setting'

      it 'can be accessed via a normal hash syntax' do
        config.set(setting, value)

        expect(config.get(['user', 'foo', 'bar'])).to eq('baz' => { 'setting' => value })
        expect(config.get(['user', 'foo', 'bar', 'baz', 'setting'])).to eq(value)
      end

      it_behaves_like 'a new setting file', "{\n  \"bar\": {\n    \"baz\": {\n      \"setting\": \"mock_value\"\n    }\n  }\n}"
    end

    context 'given a hash nested setting that already partially exists' do
      let(:setting) { ['user', 'foo', 'bar', 'baz', 'setting'] }
      let(:foo_file_content) { '{ "bar": { "existing_setting": "exists" }}' }

      it 'can be accessed via a normal hash syntax' do
        # The old setting should exist
        expect(config.get(['user', 'foo', 'bar'])).to eq('existing_setting' => 'exists')

        config.set(setting, value)

        # Should still contain the old setting
        expect(config.get(['user', 'foo', 'bar'])).to eq('baz' => { 'setting' => 'mock_value' }, 'existing_setting' => 'exists')
        # Should contain the new setting
        expect(config.get(['user', 'foo', 'bar', 'baz', 'setting'])).to eq(value)
      end

      it_behaves_like 'a new setting file', "{\n  \"bar\": {\n    \"existing_setting\": \"exists\",\n    \"baz\": {\n      \"setting\": \"mock_value\"\n    }\n  }\n}"
    end

    context 'given a hash nested setting that already exists as an Array' do
      let(:setting) { ['user', 'foo', 'bar', 'baz', 'setting'] }
      let(:foo_file_content) { '{ "bar": [] }' }

      context 'without forcing the change' do
        it 'raises an error' do
          result = config
          # The old setting should exist
          expect(result.get(['user', 'foo', 'bar'])).to eq([])
          expect { result.set(setting, value) }.to raise_error(ArgumentError)
        end
      end

      context 'when forcing the change' do
        let(:set_options) { { force: true } }

        it 'uses the new setting' do
          # The old setting should exist
          expect(config.get(['user', 'foo', 'bar'])).to eq([])

          config.set(setting, value, set_options)

          # Should contain only new setting
          expect(config.get(['user', 'foo', 'bar', 'baz', 'setting'])).to eq(value)
        end

        it_behaves_like 'a new setting file', "{\n  \"bar\": {\n    \"baz\": {\n      \"setting\": \"mock_value\"\n    }\n  }\n}"
      end
    end

    context 'given a setting that already exists as an non-empty Array' do
      let(:setting) { ['user', 'foo', 'bar'] }
      let(:foo_file_content) { '{ "bar": ["abc", "def"] }' }

      context 'without forcing the change' do
        it 'appends the new value' do
          config.set(setting, value, set_options)
          expect(config.get(['user', 'foo', 'bar'])).to eq(['abc', 'def', value])
        end

        it_behaves_like 'a new setting file', "{\n  \"bar\": [\n    \"abc\",\n    \"def\",\n    \"mock_value\"\n  ]\n}"
      end

      context 'forcing the change' do
        let(:set_options) { { force: true } }

        it 'uses the new value' do
          config.set(setting, value, set_options)
          expect(config.get(['user', 'foo', 'bar'])).to eq(value)
        end

        it_behaves_like 'a new setting file', "{\n  \"bar\": \"mock_value\"\n}"
      end
    end

    context 'given a setting that already has the value in the Array' do
      let(:setting) { ['user', 'foo', 'bar'] }
      let(:foo_file_content) { "{ \"bar\": [\"abc\", \"#{value}\"] }" }

      context 'without forcing the change' do
        it 'does not append the new value' do
          expect(PDK::Util::Filesystem).not_to receive(:write_file).with(PDK::Util::Filesystem.expand_path(foo_file), anything)
          config.set(setting, value, set_options)
          expect(config.get(['user', 'foo', 'bar'])).to eq(['abc', value])
        end
      end

      context 'forcing the change' do
        let(:set_options) { { force: true } }

        it 'uses the new value' do
          config.set(setting, value, set_options)
          expect(config.get(['user', 'foo', 'bar'])).to eq(value)
        end

        it_behaves_like 'a new setting file', "{\n  \"bar\": \"mock_value\"\n}"
      end
    end
  end
end
