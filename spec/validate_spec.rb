require 'spec_helper'

describe PDK::Validate do
  include_context :validators

  it 'includes each of the validation tools' do
    expect(subject.validators).to eq(validators)
  end
end
