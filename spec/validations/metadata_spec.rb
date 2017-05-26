require 'spec_helper'

describe PDK::Validate::Metadata do
  it 'invokes `metadata-json-lint`' do
    expect(described_class.cmd).to eq('metadata-json-lint')
  end
end
