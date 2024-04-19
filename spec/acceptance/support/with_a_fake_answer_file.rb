RSpec.shared_context 'with a fake answer file' do |initial_content = nil|
  before(:all) do
    fake_answer_file = Tempfile.new('mock_answers.json')
    unless initial_content.nil?
      require 'json'
      fake_answer_file.binmode
      fake_answer_file.write(JSON.pretty_generate(initial_content))
    end
    fake_answer_file.close
    ENV['PDK_ANSWER_FILE'] = fake_answer_file.path
  end

  after(:all) do
    FileUtils.rm_f(ENV.fetch('PDK_ANSWER_FILE', nil)) # Need actual file calls here
    ENV.delete('PDK_ANSWER_FILE')
  end
end
