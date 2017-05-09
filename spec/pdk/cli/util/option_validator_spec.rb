require 'spec_helper'
require 'pdk/cli/util/option_validator'

describe PDK::CLI::Util::OptionValidator do
  context 'when verifying comma-separated lists' do
    it 'should return true if the list is comma separated' do
      expect(described_class.is_comma_separated_list?('a,b,c')).to eq(true)
    end

    it 'should return false if the list is not comma separated' do
      expect(described_class.is_comma_separated_list?('a,b c,d')).to eq(false)
    end
  end

  context 'when verifying a value exists in an enum' do
    it 'should succeed when a single value is provided which exists' do
      expect(described_class.enum('lint', %w[lint foo])).to eq('lint')
    end

    it 'should raise an error when a single values is provided which does not exist' do
      expect { described_class.enum('foo', %w[lint bar]) }.to raise_error('Error: the following values are invalid: ["foo"]')
    end

    it 'should succeed when an array of values are provided and they all exist' do
      expect(described_class.enum(%w[lint foo], %w[lint foo])).to eq(%w[lint foo])
    end

    it 'should raise an error when an array of values is provided and one does not exist' do
      expect { described_class.enum(%w[lint foo bar], ['lint']) }.to raise_error('Error: the following values are invalid: ["foo", "bar"]')
    end
  end
end
