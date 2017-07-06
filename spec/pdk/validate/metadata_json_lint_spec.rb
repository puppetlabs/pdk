require 'spec_helper'

describe PDK::Validate::MetadataJSONLint do
  it 'invokes `metadata-json-lint`' do
    allow(PDK::Util).to receive(:module_root).and_return('/')

    expect(described_class.cmd).to match(%r{metadata-json-lint$})
  end
end
