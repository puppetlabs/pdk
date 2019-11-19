require 'spec_helper'
require 'yaml'
require 'pdk/module/template_dir/base'

describe PDK::Module::TemplateDir::Base do
  it 'has a metadata method' do
    expect(described_class.instance_methods(false)).to include(:metadata)
  end
end
