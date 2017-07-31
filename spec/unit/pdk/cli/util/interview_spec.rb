require 'spec_helper'

describe 'Module interview' do
  subject(:interview) { PDK::CLI::Util::Interview }

  it 'initially has 0 questions' do
    expect(interview.new({}, {}).num_questions).to eq(0)
  end
end
