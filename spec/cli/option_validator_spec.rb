require 'spec_helper'
require 'pdk/cli/util/option_validator'

shared_examples_for :it_accepts_a_lowercase_word do
  it 'accepts a lowercase word' do |example|
    expect(subject.send(example.metadata[:method], 'test')).to be true
  end
end

shared_examples_for :it_accepts_lowercase_digits_and_underscores do
  it 'accepts lowercase letters, digits and underscores' do |example|
    expect(subject.send(example.metadata[:method], 'test_123')).to be true
  end
end

shared_examples_for :it_rejects_an_empty_value do
  it 'rejects nil' do |example|
    expect(subject.send(example.metadata[:method], nil)).to be false
  end

  it 'rejects an empty string' do |example|
    expect(subject.send(example.metadata[:method], '')).to be false
  end
end

shared_examples_for :it_rejects_non_ascii do
  it 'rejects a string containing non-ASCII characters' do |example|
    expect(subject.send(example.metadata[:method], 'tést')).to be false
  end
end

shared_examples_for :it_rejects_strings_not_starting_with_lowercase_char do
  it 'rejects a string starting with a digit' do |example|
    expect(subject.send(example.metadata[:method], "123_test")).to be false
  end

  it 'rejects a string starting with an underscore' do |example|
    expect(subject.send(example.metadata[:method], '_test')).to be false
  end

  it 'rejects a string starting with an uppercase letter' do |example|
    expect(subject.send(example.metadata[:method], 'Test')).to be false
  end
end

shared_examples_for :it_rejects_uppercase_chars do
  it 'rejects a string containing uppercase letters' do |example|
    expect(subject.send(example.metadata[:method], 'testThing')).to be false
  end
end


describe PDK::CLI::Util::OptionValidator do
  subject { described_class }

  context 'when verifying comma-separated lists' do
    it { is_expected.to respond_to(:is_comma_separated_list?).with(1).argument }

    it 'should return true if the list is comma separated' do
      expect(subject.is_comma_separated_list?('a,b,c')).to eq(true)
    end

    it 'should return false if the list is not comma separated' do
      expect(subject.is_comma_separated_list?('a,b c,d')).to eq(false)
    end
  end

  context 'when verifying a value exists in an enum' do
    it { is_expected.to respond_to(:enum).with(2).arguments }

    it 'should succeed when a single value is provided which exists' do
      expect(subject.enum('lint', %w(lint foo))).to eq('lint')
    end

    it 'should raise an error when a single values is provided which does not exist' do
      expect { subject.enum('foo', %w(lint bar)) }.to raise_error('Error: the following values are invalid: ["foo"]')
    end

    it 'should succeed when an array of values are provided and they all exist' do
      expect(subject.enum(%w(lint foo), %w(lint foo))).to eq(%w(lint foo))
    end

    it 'should raise an error when an array of values is provided and one does not exist' do
      expect { subject.enum(%w(lint foo bar), ['lint']) }.to raise_error('Error: the following values are invalid: ["foo", "bar"]')
    end
  end

  context 'is_valid_module_name?', :method => :is_valid_module_name? do
    it { is_expected.to respond_to(:is_valid_module_name?).with(1).argument }

    it_behaves_like :it_accepts_a_lowercase_word
    it_behaves_like :it_accepts_lowercase_digits_and_underscores
    it_behaves_like :it_rejects_an_empty_value
    it_behaves_like :it_rejects_non_ascii
    it_behaves_like :it_rejects_strings_not_starting_with_lowercase_char
    it_behaves_like :it_rejects_uppercase_chars
  end

  context 'is_valid_class_name?', :method => :is_valid_class_name? do
    it { is_expected.to respond_to(:is_valid_class_name?).with(1).argument }

    it_behaves_like :it_accepts_a_lowercase_word
    it_behaves_like :it_accepts_lowercase_digits_and_underscores
    it_behaves_like :it_rejects_an_empty_value
    it_behaves_like :it_rejects_non_ascii
    it_behaves_like :it_rejects_strings_not_starting_with_lowercase_char
    it_behaves_like :it_rejects_uppercase_chars

    it 'accepts a valid segmented namespace' do
      expect(subject.is_valid_class_name?('testmodule::testclass')).to be true
    end

    it 'rejects the string "init"' do
      expect(subject.is_valid_class_name?('init')).to be false
    end
  end

  context 'is_valid_param_name?', :method => :is_valid_param_name? do
    it { is_expected.to respond_to(:is_valid_param_name?).with(1).argument }

    it_behaves_like :it_accepts_a_lowercase_word
    it_behaves_like :it_accepts_lowercase_digits_and_underscores
    it_behaves_like :it_rejects_an_empty_value
    it_behaves_like :it_rejects_non_ascii
    it_behaves_like :it_rejects_strings_not_starting_with_lowercase_char

    it 'rejects reserved variable names' do
      %w{trusted facts server_facts title name}.each do |reserved_word|
        expect(subject.is_valid_param_name?(reserved_word)).to be false
      end
    end

    it 'rejects metaparameter names' do
      %w{alias audit before loglevel noop notify require schedule stage subscribe tag}.each do |metaparam|
        expect(subject.is_valid_param_name?(metaparam)).to be false
      end
    end
  end

  context 'is_valid_data_type?' do
    it { is_expected.to respond_to(:is_valid_data_type?).with(1).argument }

    it 'accepts known data types' do
      %w{String Integer Float Numeric Boolean Array Hash Regexp Undef Default
        Class Resource Scalar Collection Variant Data Pattern Enum Tuple Struct
        Optional Catalogentry Type Any Callable NotUndef
      }.each do |data_type|
        expect(subject.is_valid_data_type?(data_type)).to be true
      end
    end

    it 'accepts abstract data types' do
      expect(subject.is_valid_data_type?('Variant[Integer, Enum["absent", "present"]]')).to be true
    end

    it 'rejects non-capitalised data types' do
      expect(subject.is_valid_data_type?('string')).to be false
    end

    it 'checks all the data types in an abstract data type' do
      expect(subject.is_valid_data_type?('Variant[Integer, boolean, String]')).to be false
    end
  end
end
