require 'spec_helper'

describe PDK::Module::TemplateDir do
  it 'has a metadata method' do
    expect(described_class.instance_methods(false)).to include(:metadata)
  end
end
