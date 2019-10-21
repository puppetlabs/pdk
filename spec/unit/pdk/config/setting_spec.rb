require 'spec_helper'
require 'pdk/config/setting'

describe PDK::Config::Setting do
  subject(:namespace) { PDK::Config::Namespace.new('rspec') }

  subject(:config_setting) { described_class.new(name, namespace) }

  let(:name) { 'my_config_setting' }

  describe '#qualified_name' do
    it 'appends the setting name to its namespace name' do
      expect(config_setting.qualified_name).to eq('rspec.my_config_setting')
    end
  end

  describe '#value' do
    it 'is nil on creation' do
      setting = described_class.new(name, namespace)
      expect(setting.value).to be_nil
    end

    it 'can be set on creation' do
      setting = described_class.new(name, namespace, 'foo-bar')
      expect(setting.value).to eq('foo-bar')
    end
  end

  describe '#value=' do
    let(:new_value) { 'new' }

    before(:each) do
      allow(config_setting).to receive(:validate!) # rubocop:disable RSpec/SubjectStub Ignore
    end

    it 'validates the new value' do
      expect(config_setting).to receive(:validate!).with(new_value) # rubocop:disable RSpec/SubjectStub Ignore
      config_setting.value = new_value
    end

    it 'sets the new value' do
      expect(config_setting.value).to be_nil
      config_setting.value = new_value
      expect(config_setting.value).to eq(new_value)
    end

    context 'when validate fails' do
      before(:each) do
        expect(config_setting).to receive(:validate!).and_raise(ArgumentError, 'Mock Validation Error') # rubocop:disable RSpec/SubjectStub Ignore
      end

      it 'does not set the new value' do
        expect(config_setting.value).to be_nil
        expect { config_setting.value = new_value }.to raise_error(ArgumentError)
        expect(config_setting.value).to be_nil
      end
    end
  end

  describe '#to_s' do
    let(:value) { { 'a' => 'b' } }

    it 'returns the value as a string' do
      config_setting.value = value
      expect(config_setting.to_s).to eq(value.to_s)
    end
  end

  describe '#validate' do
    subject(:validate) { config_setting.validate(validator) }

    context 'when passed an object that is not a Hash' do
      let(:validator) { ->(_) { true } }

      it 'raises an error' do
        expect { validate }.to raise_error(ArgumentError, '`validator` must be a Hash')
      end
    end

    context 'when passed a Hash without a :proc key' do
      let(:validator) { { message: 'test message' } }

      it 'raises an error' do
        expect { validate }.to raise_error(ArgumentError, 'the :proc key must contain a Proc')
      end
    end

    context 'when passed a Hash with a :proc key that does not contain a Proc' do
      let(:validator) { { proc: true, message: 'test message' } }

      it 'raises an error' do
        expect { validate }.to raise_error(ArgumentError, 'the :proc key must contain a Proc')
      end
    end

    context 'when passed a Hash without a :message key' do
      let(:validator) { { proc: ->(_) { true } } }

      it 'raises an error' do
        expect { validate }.to raise_error(ArgumentError, 'the :message key must contain a String')
      end
    end

    context 'when passed a Hash with a :message key that does not contain a string' do
      let(:validator) { { proc: ->(_) { true }, message: true } }

      it 'raises an error' do
        expect { validate }.to raise_error(ArgumentError, 'the :message key must contain a String')
      end
    end

    context 'when passed a valid validator Hash' do
      let(:validator) { { proc: ->(_) { true }, message: 'passing validator' } }

      it 'does not raise an error' do
        expect { validate }.not_to raise_error
      end
    end
  end

  describe '#validate!' do
    subject(:validate!) { config_setting.validate!(value) }

    let(:full_key_name) { "rspec.#{name}" }
    let(:value) { 'a value' }

    context 'when there are no validators' do
      it 'does not raise an error' do
        expect { validate! }.not_to raise_error
      end
    end

    context 'when there is a passing validator' do
      before(:each) do
        config_setting.validate(proc: ->(_) { true }, message: 'always passes')
      end

      it 'does not raise an error' do
        expect { validate! }.not_to raise_error
      end
    end

    context 'when there is a failing validator' do
      before(:each) do
        config_setting.validate(proc: ->(_) { false }, message: 'always fails')
      end

      it 'raises an error' do
        expect { validate! }.to raise_error(ArgumentError, "#{full_key_name} always fails")
      end
    end

    context 'when there are multiple validators' do
      before(:each) do
        config_setting.validate(proc: ->(_) { true }, message: 'always passes')
        config_setting.validate(proc: ->(_) { false }, message: 'always fails 1')
        config_setting.validate(proc: ->(_) { false }, message: 'always fails 2')
      end

      it 'raises an error for the first failing validator' do
        expect { validate! }.to raise_error(ArgumentError, "#{full_key_name} always fails 1")
      end
    end
  end

  describe '#default_to' do
    context 'when passed a block' do
      it 'does not raise an error' do
        expect { config_setting.default_to { 'a value' } }.not_to raise_error
      end
    end

    context 'when not passed a block' do
      it 'raises an error' do
        expect { config_setting.default_to }.to raise_error(ArgumentError, 'must be passed a block')
      end
    end
  end

  describe '#default' do
    subject(:default) { config_setting.default }

    context 'when there is no default value Proc for the setting' do
      it { is_expected.to be_nil }
    end

    context 'when there is a default value Proc for the setting' do
      before(:each) do
        config_setting.default_to { 'a value' }
      end

      it 'returns the return value of the Proc' do
        expect(default).to eq('a value')
      end
    end

    context 'when there is a settings chain' do
      before(:each) do
        child_config_setting = described_class.new('child_setting', namespace)
        child_config_setting.default_to { 'a child value' }
        config_setting.previous_setting = child_config_setting
      end

      context 'and there is a default value Proc for the setting' do
        before(:each) do
          config_setting.default_to { 'a value' }
        end

        it 'returns the return value of the Proc' do
          expect(default).to eq('a value')
        end
      end

      context 'and there is no default value Proc for the setting' do
        it 'returns the return value of the child Proc' do
          expect(default).to eq('a child value')
        end
      end
    end
  end
end
