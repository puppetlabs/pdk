require 'spec_helper'
require 'pdk/config/validator'

describe PDK::Config::Validator do
  describe '.boolean' do
    subject(:validator) { described_class.boolean }

    it 'returns a hash with a :proc and :message' do
      expect(validator).to include(:proc, :message)
    end

    it 'has the correct error message' do
      expect(validator[:message]).to eq('must be a boolean: true or false')
    end

    describe 'the validation proc' do
      subject(:validate) { validator[:proc] }

      it 'accepts true' do
        expect(validate.call(true)).to be_truthy
      end

      it 'accepts false' do
        expect(validate.call(false)).to be_truthy
      end

      it 'rejects a string' do
        expect(validate.call('true')).to be_falsey
      end

      it 'rejects nil' do
        expect(validate.call(nil)).to be_falsey
      end

      it 'rejects an integer' do
        expect(validate.call(1)).to be_falsey
      end
    end
  end

  describe '.uuid' do
    subject(:validator) { described_class.uuid }

    it 'returns a hash with a :proc and :message' do
      expect(validator).to include(:proc, :message)
    end

    it 'has the correct error message' do
      expect(validator[:message]).to eq('must be a version 4 UUID')
    end

    describe 'the validation proc' do
      subject(:validate) { validator[:proc] }

      it 'accepts a valid UUID' do
        expect(validate.call('550e8400-e29b-41d4-a716-446655440000')).to be_truthy
      end

      it 'rejects a string that is not a UUID' do
        expect(validate.call('not-a-uuid')).to be_falsey
      end

      it 'rejects an empty string' do
        expect(validate.call('')).to be_falsey
      end

      it 'rejects a UUID with wrong segment lengths' do
        expect(validate.call('550e8400-e29b-a716-446655440000')).to be_falsey
      end
    end
  end
end
