require 'spec_helper'
require 'securerandom'

describe PDK::Config do
  subject(:config) { described_class.new }

  let(:answer_file_content) { '{}' }
  let(:user_config_content) { '{}' }
  let(:bolt_analytics_content) { '' }
  let(:analytics_config_content) { '' }

  def mock_file(path, content)
    allow(PDK::Util::Filesystem).to receive(:write_file).with(File.expand_path(path), anything)
    allow(PDK::Util::Filesystem).to receive(:read_file).with(File.expand_path(path), anything).and_return(content)
  end

  before(:each) do
    allow(PDK::Util).to receive(:configdir).and_return(File.join('path', 'to', 'configdir'))
    mock_file(PDK.answers.answer_file_path, answer_file_content)
    mock_file(described_class.analytics_config_path, analytics_config_content)
    mock_file(described_class.user_config_path, user_config_content)
    mock_file('~/.puppetlabs/bolt/analytics.yaml', bolt_analytics_content)
  end

  describe 'user.analytics.disabled' do
    context 'set' do
      it 'can be set to true' do
        expect { config.user['analytics']['disabled'] = true }.not_to raise_error
      end

      it 'can be set to false' do
        expect { config.user['analytics']['disabled'] = false }.not_to raise_error
      end

      it 'can not be set to a string' do
        expect { config.user['analytics']['disabled'] = 'no' }.to raise_error(%r{must be a boolean})
      end
    end

    context 'default value' do
      context 'when there is no pre-existing bolt configuration' do
        it 'returns false' do
          expect(config.user['analytics']['disabled']).to be_falsey
        end
      end

      context 'when there is a pre-existing bolt configuration' do
        let(:bolt_analytics_content) { "---\ndisabled: true\n" }

        it 'returns the value from the bolt configuration' do
          expect(config.user['analytics']['disabled']).to be_truthy
        end
      end
    end
  end

  describe 'user.analytics.uuid' do
    context 'set' do
      it 'can be set to a string that looks like a V4 UUID' do
        expect { config.user['analytics']['uuid'] = SecureRandom.uuid }.not_to raise_error
      end

      it 'can not be set to other values' do
        expect { config.user['analytics']['uuid'] = 'totally a UUID' }.to raise_error(%r{must be a version 4 UUID})
      end
    end

    context 'default value' do
      context 'when there is no pre-existing bolt configuration' do
        it 'generates a new UUID' do
          expect(SecureRandom).to receive(:uuid).and_call_original
          config.user['analytics']['uuid']
        end
      end

      context 'when there is a pre-existing bolt configuration' do
        let(:uuid) { SecureRandom.uuid }
        let(:bolt_analytics_content) { "---\nuuid: #{uuid}\n" }

        it 'returns the value from the bolt configuration' do
          expect(config.user['analytics']['uuid']).to eq(uuid)
        end
      end
    end
  end
end
