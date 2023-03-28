RSpec.shared_context 'with a fake TTY' do
  around do |example|
    ENV['PDK_FRONTEND'] = 'INTERACTIVE'
    example.run
    ENV.delete('PDK_FRONTEND')
  end
end
