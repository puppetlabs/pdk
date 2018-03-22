# frozen_string_literal: true

require 'spec_helper'

describe PDK::CLI::FatalError do # rubocop:disable RSpec/MultipleDescribes
  subject(:error) { described_class.new }

  it 'has a default error message' do
    expect(error.message).to match(%r{an unexpected error has occurred}i)
  end

  it 'has a default non-zero exit code' do
    expect(error.exit_code).to be_an(Integer)
    expect(error.exit_code).not_to be_zero
  end

  context 'when provided a custom error message' do
    subject(:error) { described_class.new('test message') }

    it 'uses the custom error message' do
      expect(error.message).to eq('test message')
    end

    context 'and a custom exit code' do
      subject(:error) { described_class.new('test message', exit_code: 2) }

      it 'uses the custom exit code' do
        expect(error.exit_code).to eq(2)
      end
    end
  end
end

describe PDK::CLI::ExitWithError do
  subject(:error) { described_class.new(message, options) }

  let(:message) { 'test message' }
  let(:options) { {} }

  it 'uses the provided error message' do
    expect(error.message).to eq(message)
  end

  it 'has a default non-zero exit code' do
    expect(error.exit_code).to be_an(Integer)
    expect(error.exit_code).not_to be_zero
  end

  it 'has a default log level of error' do
    expect(error.log_level).to eq(:error)
  end

  context 'when provided with a custom exit code' do
    let(:options) { { exit_code: 2 } }

    it 'uses the custom exit code' do
      expect(error.exit_code).to eq(2)
    end
  end

  context 'when provided with a custom log level' do
    let(:options) { { log_level: :info } }

    it 'uses the custom log level' do
      expect(error.log_level).to eq(:info)
    end
  end
end
