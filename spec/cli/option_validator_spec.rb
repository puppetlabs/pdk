require 'spec_helper'
require 'pick/cli/util/option_validator'

describe Pick::CLI::Util::OptionValidator do
  context 'when verifying comma-separated lists' do
    it 'should normalize and return an array of strings' do
      expect(described_class.list('a,b,c')).to eq(%w(a b c))
    end

    it 'should raise an error when the list is invalid' do
      expect { described_class.list('a,b c,d') }.to raise_error('Error: expected comma separated list')
    end
  end

  context 'when verifying a value exists in an enum' do
    it 'should succeed when a single value is provided which exists' do
      expect(described_class.enum('lint', %w(lint foo))).to eq('lint')
    end

    it 'should raise an error when a single values is provided which does not exist' do
      expect { described_class.enum('foo', %w(lint bar)) }.to raise_error('Error: the following values are invalid: ["foo"]')
    end

    it 'should succeed when an array of values are provided and they all exist' do
      expect(described_class.enum(%w(lint foo), %w(lint foo))).to eq(%w(lint foo))
    end

    it 'should raise an error when an array of values is provided and one does not exist' do
      expect { described_class.enum(%w(lint foo bar), ['lint']) }.to raise_error('Error: the following values are invalid: ["foo", "bar"]')
    end
  end
end
