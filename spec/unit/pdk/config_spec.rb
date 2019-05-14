require 'spec_helper'
require 'securerandom'

describe PDK::Config do
  subject(:config) { described_class.new }

  let(:answer_file_content) { '{}' }
  let(:user_config_content) { '{}' }
  let(:analytics_config_content) { nil }
  let(:bolt_analytics_content) { nil }

  def mock_file(path, content)
    allow(PDK::Util::Filesystem).to receive(:file?).with(File.expand_path(path)).and_return(true)
    allow(PDK::Util::Filesystem).to receive(:write_file).with(File.expand_path(path), anything)
    allow(PDK::Util::Filesystem).to receive(:read_file).with(File.expand_path(path)).and_return(content)
  end

  before(:each) do
    allow(PDK::Util::Filesystem).to receive(:file?).with(anything).and_return(false)
    allow(PDK::Util).to receive(:configdir).and_return(File.join('path', 'to', 'configdir'))
    mock_file(PDK.answers.answer_file_path, answer_file_content)
    mock_file(described_class.analytics_config_path, analytics_config_content)
    mock_file(described_class.user_config_path, user_config_content)
    mock_file('~/.puppetlabs/bolt/analytics.yaml', bolt_analytics_content) if bolt_analytics_content
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
        it 'returns true' do
          expect(config.user['analytics']['disabled']).to be_truthy
        end
      end

      context 'when there is a pre-existing bolt configuration' do
        let(:bolt_analytics_content) { "---\ndisabled: false\n" }

        it 'returns the value from the bolt configuration' do
          expect(config.user['analytics']['disabled']).to be_falsey
        end
      end
    end
  end

  describe 'user.analytics.user-id' do
    context 'set' do
      it 'can be set to a string that looks like a V4 UUID' do
        expect { config.user['analytics']['user-id'] = SecureRandom.uuid }.not_to raise_error
      end

      it 'can not be set to other values' do
        expect { config.user['analytics']['user-id'] = 'totally a UUID' }.to raise_error(%r{must be a version 4 UUID})
      end
    end

    context 'default value' do
      context 'when there is no pre-existing bolt configuration' do
        it 'generates a new UUID' do
          expect(SecureRandom).to receive(:uuid).and_call_original
          config.user['analytics']['user-id']
        end
      end

      context 'when there is a pre-existing bolt configuration' do
        let(:uuid) { SecureRandom.uuid }
        let(:bolt_analytics_content) { "---\nuser-id: #{uuid}\n" }

        it 'returns the value from the bolt configuration' do
          expect(config.user['analytics']['user-id']).to eq(uuid)
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

      allow(PDK).to receive(:config).and_return(
        instance_double(described_class, user: described_class::Namespace.new('user')),
      )
      allow(PDK::CLI::Util).to receive(:interactive?).and_return(true)

      described_class.analytics_config_interview!
    end

    context 'when the user responds yes' do
      let(:responses) { ['yes'] }

      it 'sets user.analytics.disabled to false' do
        expect(PDK.config.user['analytics']['disabled']).to be_falsey
      end
    end

    context 'when the user responds no' do
      let(:responses) { ['no'] }

      it 'sets user.analytics.disabled to true' do
        expect(PDK.config.user['analytics']['disabled']).to be_truthy
      end
    end

    context 'when the user just hits enter' do
      let(:responses) { [''] }

      it 'sets user.analytics.disabled to false' do
        expect(PDK.config.user['analytics']['disabled']).to be_falsey
      end
    end

    context 'when the user cancels the interview' do
      let(:responses) { ["\003"] } # \003 == Ctrl-C

      it 'sets user.analytics.disabled to true' do
        expect(PDK.config.user['analytics']['disabled']).to be_truthy
      end
    end
  end
end
