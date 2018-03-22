# frozen_string_literal: true

require 'spec_helper'

describe PDK::Validate do
  include_context :validators

  it 'includes each of the validation tools' do
    expect(described_class.validators).to eq(validators)
  end
end
