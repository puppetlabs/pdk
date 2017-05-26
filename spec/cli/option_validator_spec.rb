require 'spec_helper'
require 'pdk/cli/util/option_validator'

describe PDK::CLI::Util::OptionValidator do
  subject { described_class }

  context 'when verifying comma-separated lists' do
    it { is_expected.to respond_to(:is_comma_separated_list?).with(1).argument }

    it 'returns true if the list is comma separated' do
      expect(subject.is_comma_separated_list?('a,b,c')).to eq(true)
    end

    it 'returns false if the list is not comma separated' do
      expect(subject.is_comma_separated_list?('a,b c,d')).to eq(false)
    end
  end

  context 'when verifying a value exists in an enum' do
    it { is_expected.to respond_to(:enum).with(2).arguments }

    it 'succeeds when a single value is provided which exists' do
      expect(subject.enum('lint', %w[lint foo])).to eq('lint')
    end

    it 'raises an error when a single values is provided which does not exist' do
      expect { subject.enum('foo', %w[lint bar]) }.to raise_error('Error: the following values are invalid: ["foo"]')
    end

    it 'succeeds when an array of values are provided and they all exist' do
      expect(subject.enum(%w[lint foo], %w[lint foo])).to eq(%w[lint foo])
    end

    it 'raises an error when an array of values is provided and one does not exist' do
      expect { subject.enum(%w[lint foo bar], ['lint']) }.to raise_error('Error: the following values are invalid: ["foo", "bar"]')
    end
  end

  context 'when verifying a module name' do
    it { is_expected.to respond_to(:is_valid_module_name?).with(1).argument }

    it 'returns true if passed a lowercase word' do
      expect(subject.is_valid_module_name?('test')).to be true
    end

    it 'returns true if passed a string containing only lowercase letters, digits, and underscores' do
      expect(subject.is_valid_module_name?('test_123')).to be true
    end

    it 'returns false if passed nil' do
      expect(subject.is_valid_module_name?(nil)).to be false
    end

    it 'returns false if passed an empty string' do
      expect(subject.is_valid_module_name?('')).to be false
    end

    it 'returns false if passed a string containing only valid characters but not starting with a lowercase letter' do
      expect(subject.is_valid_module_name?('123_test')).to be false
    end

    it 'returns false if passed a string containing uppercase letters' do
      expect(subject.is_valid_module_name?('testThing')).to be false
    end
  end
end
