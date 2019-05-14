require 'spec_helper'

describe PDK::Config::Value do
  subject(:config_value) { described_class.new(name) }

  let(:name) { 'my_config_value' }

  describe '#validate' do
    subject(:validate) { config_value.validate(validator) }

    context 'when passed an object that is not a Hash' do
      let(:validator) { ->(_) { true } }

      it 'raises an error' do
        expect { validate }.to raise_error(ArgumentError, 'validator must be a Hash')
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
    subject(:validate!) { config_value.validate!(key, value) }

    let(:key) { 'user.foo.bar' }
    let(:value) { 'a value' }

    context 'when there are no validators' do
      it 'does not raise an error' do
        expect { validate! }.not_to raise_error
      end
    end

    context 'when there is a passing validator' do
      before(:each) do
        config_value.validate(proc: ->(_) { true }, message: 'always passes')
      end

      it 'does not raise an error' do
        expect { validate! }.not_to raise_error
      end
    end

    context 'when there is a failing validator' do
      before(:each) do
        config_value.validate(proc: ->(_) { false }, message: 'always fails')
      end

      it 'raises an error' do
        expect { validate! }.to raise_error(ArgumentError, "#{key} always fails")
      end
    end

    context 'when there are multiple validators' do
      before(:each) do
        config_value.validate(proc: ->(_) { true }, message: 'always passes')
        config_value.validate(proc: ->(_) { false }, message: 'always fails 1')
        config_value.validate(proc: ->(_) { false }, message: 'always fails 2')
      end

      it 'raises an error for the first failing validator' do
        expect { validate! }.to raise_error(ArgumentError, "#{key} always fails 1")
      end
    end
  end

  describe '#default_to' do
    context 'when passed a block' do
      it 'does not raise an error' do
        expect { config_value.default_to { 'a value' } }.not_to raise_error
      end
    end

    context 'when not passed a block' do
      it 'raises an error' do
        expect { config_value.default_to }.to raise_error(ArgumentError, 'must be passed a block')
      end
    end
  end

  describe '#default?' do
    subject(:default?) { config_value.default? }

    context 'when there is no default value Proc for the value' do
      it { is_expected.to be_falsey }
    end

    context 'when there is a default value Proc for the value' do
      before(:each) do
        config_value.default_to { 'a default value' }
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#default' do
    subject(:default) { config_value.default }

    context 'when there is no default value Proc for the value' do
      it { is_expected.to be_nil }
    end

    context 'when there is a default value Proc for the value' do
      before(:each) do
        config_value.default_to { 'a value' }
      end

      it 'returns the return value of the Proc' do
        expect(default).to eq('a value')
      end
    end
  end
end
