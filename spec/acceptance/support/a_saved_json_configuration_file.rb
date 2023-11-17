RSpec.shared_examples 'a saved JSON configuration file' do |new_json_content|
  it 'saves the setting' do
    # Force the command to run if not already
    subject.exit_status
    expect(File).to exist(ENV.fetch('PDK_ANSWER_FILE', nil))

    actual_content_raw = File.open(ENV.fetch('PDK_ANSWER_FILE', nil), 'rb:utf-8', &:read)
    actual_json_content = JSON.parse(actual_content_raw)
    expect(actual_json_content).to eq(new_json_content)
  end
end
