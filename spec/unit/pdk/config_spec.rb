require 'spec_helper'
require 'securerandom'
require 'tty/test_prompt'
require 'pdk/config'

describe PDK::Config do
  subject(:config) { described_class.new }

  include_context 'mock configuration'

  let(:bolt_analytics_path) { '~/.puppetlabs/bolt/analytics.yaml' }

  def mock_file(path, content)
    allow(PDK::Util::Filesystem).to receive(:file?).with(PDK::Util::Filesystem.expand_path(path)).and_return(true)
    allow(PDK::Util::Filesystem).to receive(:write_file).with(PDK::Util::Filesystem.expand_path(path), anything)
    allow(PDK::Util::Filesystem).to receive(:read_file).with(PDK::Util::Filesystem.expand_path(path)).and_return(content)
  end

  before(:each) do
    # Allow the JSON Schema documents to actually be read. Rspec matchers are LIFO
    allow(PDK::Util::Filesystem).to receive(:file?).with(%r{_schema\.json}).and_call_original
  end

  describe '.system_config' do
    it 'returns a PDK::Config::Namespace' do
      expect(config.system_config).to be_a(PDK::Config::Namespace)
    end
  end

  describe '.user_config' do
    it 'returns a PDK::Config::Namespace' do
      expect(config.user_config).to be_a(PDK::Config::Namespace)
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
    let(:bolt_analytics_content) { "---\ndisabled: true\n" }
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
        setting_name = %w[system setting child child_setting]
        expect(config.get(*setting_name)).to eq('child_setting_value')
      end

      it 'uses an Array for the setting name' do
        setting_name = %w[system setting child child_setting]
        expect(config.get(setting_name)).to eq('child_setting_value')
      end

      it 'uses a String for the setting name' do
        setting_name = 'system.setting.child.child_setting'
        expect(config.get(setting_name)).to eq('child_setting_value')
      end
    end

    it 'traverses namespaces' do
      # The analytics is a child namespace of user
      expect(config.get('user', 'analytics', 'disabled')).to eq(true)
    end

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
      let(:names) { %w[system setting missing_child child_setting] }

      it 'returns nil' do
        expect(config.get(*names)).to be_nil
      end
    end

    context 'given a root name that does not exist' do
      let(:names) { %w[missing analytics disabled] }

      it 'returns nil' do
        expect(config.get(*names)).to be_nil
      end
    end
  end

  describe '.pdk_setting' do
    subject(:setting_value) { config.pdk_setting(setting_name) }

    let(:setting_name) { 'name' }
    let(:user_value) { 'user' }
    let(:system_value) { 'system' }

    context 'given a setting that does not appear in either user or system level' do
      it 'returns nil' do
        expect(setting_value).to be_nil
      end
    end

    context 'given a setting that appears at the user level but not the system' do
      let(:user_config_content) { " { \"#{setting_name}\": \"#{user_value}\"}" }

      it 'returns the user level value' do
        expect(setting_value).to eq(user_value)
      end
    end

    context 'given a setting that appears at the system level but not the user' do
      let(:system_config_content) { " { \"#{setting_name}\": \"#{system_value}\"}" }

      it 'returns the system level value' do
        expect(setting_value).to eq(system_value)
      end
    end

    context 'given a setting that appears in both user and system level' do
      let(:user_config_content) { " { \"#{setting_name}\": \"#{user_value}\"}" }
      let(:system_config_content) { " { \"#{setting_name}\": \"#{system_value}\"}" }

      it 'returns the user level value' do
        expect(setting_value).to eq(user_value)
      end
    end
  end

  describe 'user.analytics.disabled' do
    context 'set' do
      it 'can be set to true' do
        expect { config.user_config['analytics']['disabled'] = true }.not_to raise_error
      end

      it 'can be set to false' do
        expect { config.user_config['analytics']['disabled'] = false }.not_to raise_error
      end

      it 'can not be set to a string' do
        expect { config.user_config['analytics']['disabled'] = 'no' }.to raise_error(ArgumentError)
      end
    end

    context 'default value' do
      context 'when there is no pre-existing bolt configuration' do
        it 'returns true' do
          expect(config.user_config['analytics']['disabled']).to be_truthy
        end

        it 'saves the disabled value to the analytics config file' do
          expect(PDK::Util::Filesystem).to receive(:write_file).with(PDK::Util::Filesystem.expand_path(described_class.analytics_config_path), %r{disabled: true})
          config.user_config['analytics']['disabled']
        end
      end

      context 'when there is a pre-existing bolt configuration' do
        let(:bolt_analytics_content) { "---\ndisabled: false\n" }

        it 'returns the value from the bolt configuration' do
          expect(config.user_config['analytics']['disabled']).to be_falsey
        end

        it 'saves the disabled value to the analytics config file' do
          expect(PDK::Util::Filesystem).to receive(:write_file).with(PDK::Util::Filesystem.expand_path(described_class.analytics_config_path), %r{disabled: false})
          config.user_config['analytics']['disabled']
        end

        context 'and the bolt configuration is unparsable' do
          before(:each) do
            allow(PDK::Config::YAML).to receive(:new).and_call_original
            allow(PDK::Config::YAML).to receive(:new)
              .with(file: PDK::Util::Filesystem.expand_path(bolt_analytics_path))
              .and_raise(PDK::Config::LoadError)
          end

          it 'returns true' do
            expect(config.user_config['analytics']['disabled']).to be_truthy
          end

          it 'saves the disabled value to the analytics config file' do
            expect(PDK::Util::Filesystem).to receive(:write_file).with(PDK::Util::Filesystem.expand_path(described_class.analytics_config_path), %r{disabled: true})
            config.user_config['analytics']['disabled']
          end
        end
      end
    end
  end

  describe 'user.analytics.user-id' do
    context 'set' do
      it 'can be set to a string that looks like a V4 UUID' do
        expect { config.user_config['analytics']['user-id'] = SecureRandom.uuid }.not_to raise_error
      end

      it 'can not be set to other values' do
        expect { config.user_config['analytics']['user-id'] = 'totally a UUID' }.to raise_error(ArgumentError)
      end
    end

    def uuid_regex(uuid)
      # Depending on the YAML or JSON generator, it may, or may not have quotes
      %r{user-id: (?:#{uuid}|'#{uuid}'|\"#{uuid}\")}
    end

    context 'default value' do
      context 'when there is no pre-existing bolt configuration' do
        it 'generates a new UUID' do
          expect(SecureRandom).to receive(:uuid).and_call_original
          config.user_config['analytics']['user-id']
        end

        it 'saves the UUID to the analytics config file' do
          new_id = SecureRandom.uuid
          expect(SecureRandom).to receive(:uuid).and_return(new_id)
          # Expect that the user-id is saved to the config file
          expect(PDK::Util::Filesystem).to receive(:write_file).with(PDK::Util::Filesystem.expand_path(described_class.analytics_config_path), uuid_regex(new_id))
          # ... and that it returns the new id
          expect(config.user_config['analytics']['user-id']).to eq(new_id)
        end
      end

      context 'when there is a pre-existing bolt configuration' do
        let(:uuid) { SecureRandom.uuid }
        let(:bolt_analytics_content) { "---\nuser-id: #{uuid}\n" }

        it 'returns the value from the bolt configuration' do
          expect(config.user_config['analytics']['user-id']).to eq(uuid)
        end

        it 'saves the UUID to the analytics config file' do
          # Expect that the user-id is saved to the config file
          expect(PDK::Util::Filesystem).to receive(:write_file).with(PDK::Util::Filesystem.expand_path(described_class.analytics_config_path), uuid_regex(uuid))
          config.user_config['analytics']['user-id']
        end

        context 'and the bolt configuration is unparsable' do
          before(:each) do
            allow(PDK::Config::YAML).to receive(:new).and_call_original
            allow(PDK::Config::YAML).to receive(:new)
              .with(file: PDK::Util::Filesystem.expand_path(bolt_analytics_path))
              .and_raise(PDK::Config::LoadError)
          end

          it 'generates a new UUID' do
            expect(SecureRandom).to receive(:uuid).and_call_original
            config.user_config['analytics']['user-id']
          end

          it 'saves the UUID to the analytics config file' do
            new_id = SecureRandom.uuid
            expect(SecureRandom).to receive(:uuid).and_return(new_id)
            # Expect that the user-id is saved to the config file
            expect(PDK::Util::Filesystem).to receive(:write_file).with(PDK::Util::Filesystem.expand_path(described_class.analytics_config_path), uuid_regex(new_id))
            # ... and that it returns the new id
            expect(config.user_config['analytics']['user-id']).to eq(new_id)
          end
        end
      end
    end
  end

  describe '.analytics_config_interview!' do
    before(:each) do
      prompt = TTY::TestPrompt.new
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      prompt.input << responses.join("\r") + "\r"
      prompt.input.rewind

      allow(PDK::CLI::Util).to receive(:interactive?).and_return(true)
      # Mock any file writing
      allow(PDK::Util::Filesystem).to receive(:write_file).with(anything, anything)
    end

    context 'when the user responds yes' do
      let(:responses) { ['yes'] }

      it 'sets user.analytics.disabled to false' do
        described_class.analytics_config_interview!
        expect(PDK.config.user_config['analytics']['disabled']).to be_falsey
      end
    end

    context 'when the user responds no' do
      let(:responses) { ['no'] }

      it 'sets user.analytics.disabled to true' do
        described_class.analytics_config_interview!
        expect(PDK.config.user_config['analytics']['disabled']).to be_truthy
      end
    end

    context 'when the user just hits enter' do
      let(:responses) { [''] }

      it 'sets user.analytics.disabled to false' do
        described_class.analytics_config_interview!
        expect(PDK.config.user_config['analytics']['disabled']).to be_falsey
      end
    end

    context 'when the user cancels the interview' do
      let(:responses) { ["\003"] } # \003 == Ctrl-C

      it 'sets user.analytics.disabled to true' do
        described_class.analytics_config_interview!
        expect(PDK.config.user_config['analytics']['disabled']).to be_truthy
      end
    end
  end
end
