require 'spec_helper'
require 'pdk/cli/util/option_validator'

shared_examples_for :it_accepts_a_lowercase_word do
  it 'accepts a lowercase word' do |example|
    expect(validator.send(example.metadata[:method], 'test')).to be true
  end
end

shared_examples_for :it_accepts_lowercase_digits_and_underscores do
  it 'accepts lowercase letters, digits and underscores' do |example|
    expect(validator.send(example.metadata[:method], 'test_123')).to be true
  end
end

shared_examples_for :it_rejects_an_empty_value do
  it 'rejects nil' do |example|
    expect(validator.send(example.metadata[:method], nil)).to be false
  end

  it 'rejects an empty string' do |example|
    expect(validator.send(example.metadata[:method], '')).to be false
  end
end

shared_examples_for :it_rejects_non_ascii do
  it 'rejects a string containing non-ASCII characters' do |example|
    expect(validator.send(example.metadata[:method], 'tést')).to be false
  end
end

shared_examples_for :it_rejects_strings_not_starting_with_lowercase_char do
  it 'rejects a string starting with a digit' do |example|
    expect(validator.send(example.metadata[:method], '123_test')).to be false
  end

  it 'rejects a string starting with an underscore' do |example|
    expect(validator.send(example.metadata[:method], '_test')).to be false
  end

  it 'rejects a string starting with an uppercase letter' do |example|
    expect(validator.send(example.metadata[:method], 'Test')).to be false
  end
end

shared_examples_for :it_rejects_uppercase_chars do
  it 'rejects a string containing uppercase letters' do |example|
    expect(validator.send(example.metadata[:method], 'testThing')).to be false
  end
end

describe PDK::CLI::Util::OptionValidator do
  subject(:validator) { described_class }

  context 'when verifying comma-separated lists' do
    it { is_expected.to respond_to(:comma_separated_list?).with(1).argument }

    it 'returns true if the list is comma separated' do
      expect(validator.comma_separated_list?('a,b,c')).to eq(true)
    end

    it 'returns false if the list is not comma separated' do
      expect(validator.comma_separated_list?('a,b c,d')).to eq(false)
    end
  end

  context 'when verifying a value exists in an enum' do
    it { is_expected.to respond_to(:enum).with(2).arguments }

    it 'succeeds when a single value is provided which exists' do
      expect(validator.enum('lint', ['lint', 'foo'])).to eq('lint')
    end

    it 'raises an error when a single values is provided which does not exist' do
      expect { validator.enum('foo', ['lint', 'bar']) }.to raise_error('Error: the following values are invalid: ["foo"]')
    end

    it 'succeeds when an array of values are provided and they all exist' do
      expect(validator.enum(['lint', 'foo'], ['lint', 'foo'])).to eq(['lint', 'foo'])
    end

    it 'raises an error when an array of values is provided and one does not exist' do
      expect { validator.enum(['lint', 'foo', 'bar'], ['lint']) }.to raise_error('Error: the following values are invalid: ["foo", "bar"]')
    end
  end

  context 'valid_module_name?', method: :valid_module_name? do
    it { is_expected.to respond_to(:valid_module_name?).with(1).argument }

    it_behaves_like :it_accepts_a_lowercase_word
    it_behaves_like :it_accepts_lowercase_digits_and_underscores
    it_behaves_like :it_rejects_an_empty_value
    it_behaves_like :it_rejects_non_ascii
    it_behaves_like :it_rejects_strings_not_starting_with_lowercase_char
    it_behaves_like :it_rejects_uppercase_chars
  end

  context 'valid_class_name?', method: :valid_class_name? do
    it { is_expected.to respond_to(:valid_class_name?).with(1).argument }

    it_behaves_like :it_accepts_a_lowercase_word
    it_behaves_like :it_accepts_lowercase_digits_and_underscores
    it_behaves_like :it_rejects_an_empty_value
    it_behaves_like :it_rejects_non_ascii
    it_behaves_like :it_rejects_strings_not_starting_with_lowercase_char
    it_behaves_like :it_rejects_uppercase_chars

    it 'accepts a valid segmented namespace' do
      expect(validator.valid_class_name?('testmodule::testclass')).to be true
    end

    it 'rejects the string "init"' do
      expect(validator.valid_class_name?('init')).to be false
    end
  end

  context 'valid_param_name?', method: :valid_param_name? do
    it { is_expected.to respond_to(:valid_param_name?).with(1).argument }

    it_behaves_like :it_accepts_a_lowercase_word
    it_behaves_like :it_accepts_lowercase_digits_and_underscores
    it_behaves_like :it_rejects_an_empty_value
    it_behaves_like :it_rejects_non_ascii
    it_behaves_like :it_rejects_strings_not_starting_with_lowercase_char

    it 'rejects reserved variable names' do
      ['trusted', 'facts', 'server_facts', 'title', 'name'].each do |reserved_word|
        expect(validator.valid_param_name?(reserved_word)).to be false
      end
    end

    it 'rejects metaparameter names' do
      ['alias', 'audit', 'before', 'loglevel', 'noop', 'notify', 'require', 'schedule', 'stage', 'subscribe', 'tag'].each do |metaparam|
        expect(validator.valid_param_name?(metaparam)).to be false
      end
    end
  end
end
