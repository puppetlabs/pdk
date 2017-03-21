require 'spec_helper'

describe PDK::Validate::Metadata do
  it 'should invoke `metadata-json-lint`' do
    expect(PDK::Validate::Metadata.cmd).to eq('metadata-json-lint')
  end
end
