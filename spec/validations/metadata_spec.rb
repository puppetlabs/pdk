require 'spec_helper'

describe Pick::Validate::Metadata do
  it 'should invoke `metadata-json-lint`' do
    expect(Pick::Validate::Metadata.cmd).to eq('metadata-json-lint')
  end
end
