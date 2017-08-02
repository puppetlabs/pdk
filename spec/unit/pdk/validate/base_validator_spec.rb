require 'spec_helper'

describe PDK::Validate::BaseValidator do
  context 'a class inheriting from BaseValidator' do
    subject(:validator) { Class.new(described_class) }

    it 'has an invoke method' do
      expect(validator.methods).to include(:invoke)
    end
  end
end
