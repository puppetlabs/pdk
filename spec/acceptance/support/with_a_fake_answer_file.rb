# require 'tempfile'

# RSpec.shared_context 'with a fake answer file' do |initial_content|
#   # around(:each) do |example|
#   #   @fake_answer_file = Tempfile.new('mock_answers.json')
#   #   @fake_answer_file.close
#   #   ENV['PDK_ANSWER_FILE'] = @fake_answer_file.path

#   #   example.run

#   #   ENV.delete('PDK_ANSWER_FILE')
#   #   @fake_answer_file.unlink
#   # end

#   before(:all) do
#     @fake_answer_file = Tempfile.new('mock_answers.json')
#     unless initial_content.nil?
#       require 'json'
#       @fake_answer_file.write(::JSON.pretty_generate(initial_content))
#     end
#     @fake_answer_file.close
#     ENV['PDK_ANSWER_FILE'] = @fake_answer_file.path
#   end

#   after(:all) do
#     ENV.delete('PDK_ANSWER_FILE')
#     @fake_answer_file.unlink
#   end
# end
