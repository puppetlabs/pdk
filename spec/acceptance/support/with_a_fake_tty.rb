# frozen_string_literal: true

RSpec.shared_context 'with a fake TTY' do
  around(:each) do |example|
    ENV['PDK_FRONTEND'] = 'INTERACTIVE'
    example.run
    ENV.delete('PDK_FRONTEND')
  end
end
