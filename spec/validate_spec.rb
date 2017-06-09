require 'spec_helper'

describe PDK::Validate do
  include_context :validators

  it 'should include each of the validation tools' do
    expect(subject.validators).to eq(validators)
  end
end
