RSpec.shared_context 'mock configuration' do
  let(:default_answer_file_content) { nil }
  let(:system_answers_content) { nil }
  let(:analytics_config_content) { nil }
  let(:user_config_content) { nil }
  let(:system_config_content) { nil }
  let(:bolt_analytics_content) { nil }

  let(:new_config) do
    PDK::Config.new.tap do |item|
      item.user_config.read_only!
      item.system_config.read_only!
    end
  end

  before(:each) do
    # The PDK.config method memoizes, so create a new read only config object every time
    allow(PDK).to receive(:config).and_return(new_config)

    # Mock any configuration file read/writes
    [
      { file: PDK::AnswerFile.default_answer_file_path, content: default_answer_file_content },
      { file: PDK::Config.system_answers_path, content: system_answers_content },
      { file: PDK::Config.analytics_config_path, content: analytics_config_content },
      { file: PDK::Config.user_config_path, content: user_config_content },
      { file: PDK::Config.system_config_path, content: system_config_content },
      { file: '~/.puppetlabs/bolt/analytics.yaml', content: bolt_analytics_content },
    ].each do |item|
      # If the content is nil then mock a missing file, otherwise mock a read-able file
      if item[:content].nil?
        allow(PDK::Util::Filesystem).to receive(:file?).with(PDK::Util::Filesystem.expand_path(item[:file])).and_return(false)
        allow(PDK::Util::Filesystem).to receive(:read_file).with(PDK::Util::Filesystem.expand_path(item[:file])).and_raise('Mock configuration file does not exist')
      else
        allow(PDK::Util::Filesystem).to receive(:file?).with(PDK::Util::Filesystem.expand_path(item[:file])).and_return(true)
        allow(PDK::Util::Filesystem).to receive(:read_file).with(PDK::Util::Filesystem.expand_path(item[:file])).and_return(item[:content])
      end
      allow(PDK::Util::Filesystem).to receive(:write_file).with(PDK::Util::Filesystem.expand_path(item[:file]), anything)
    end
  end
end
