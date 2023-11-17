RSpec.shared_examples 'a saved configuration file' do |new_content|
  it 'saves the setting' do
    # Force the command to run if not already
    subject.exit_status
    expect(File).to exist(ENV.fetch('PDK_ANSWER_FILE', nil))

    actual_content = File.open(ENV.fetch('PDK_ANSWER_FILE', nil), 'rb:utf-8', &:read)
    expect(actual_content).to eq(new_content)
  end
end
