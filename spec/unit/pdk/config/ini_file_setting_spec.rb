require 'spec_helper'
require 'pdk/config/ini_file_setting'

describe PDK::Config::IniFileSetting do
  subject(:setting) { described_class.new('spec_setting', namespace, initial_value) }

  let(:initial_value) { nil }

  let(:namespace) { PDK::Config::IniFile.new('spec') }

  context 'when not in an Ini File Namespace' do
    let(:namespace) { PDK::Config::Namespace.new }

    it 'raises' do
      expect { setting }.to raise_error(%r{IniFile Namespace})
    end
  end

  context 'with invalid initial value' do
    let(:initial_value) { %w[abc 123] }

    it 'raises' do
      expect { setting }.to raise_error(ArgumentError, %r{spec_setting})
    end
  end

  RSpec.shared_examples 'a setting validator' do |value_type_name, value|
    it "validates #{value_type_name}" do
      expect { setting.validate!(value) }.not_to raise_error
    end

    it "validates #{value_type_name} in a simple hash" do
      expect { setting.validate!('foo' => value) }.not_to raise_error
    end
  end

  RSpec.shared_examples 'an error raising validator' do |value_type_name, value|
    it "raises for #{value_type_name}" do
      expect { setting.validate!(value) }.to raise_error(ArgumentError, %r{spec_setting})
    end
  end

  describe '#validate!' do
    context 'with valid values' do
      include_examples 'a setting validator', 'String', 'value'
      include_examples 'a setting validator', 'Nil', nil
      include_examples 'a setting validator', 'Integer', 1
    end

    context 'with invalid values' do
      include_examples 'an error raising validator', 'Symbol', :value
      include_examples 'an error raising validator', 'Array', %w[abc 123]
      include_examples 'an error raising validator', 'Nested hash', 'foo' => { 'bar' => 'baz' }
      include_examples 'an error raising validator', 'Float', 1.0
    end
  end
end
