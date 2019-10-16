require 'spec_helper'
require 'pdk/config/yaml'

describe PDK::Config::YAML do
  subject(:yaml_config) { described_class.new(file: tempfile) }

  let(:tempfile) do
    file = Tempfile.new('test')
    file.write(data)
    file.close
    file.path
  end
  let(:data) { nil }

  it_behaves_like 'a file based namespace', "---\nfoo: bar\n", 'foo' => 'bar'

  it_behaves_like 'a file based namespace without a schema'

  it_behaves_like 'a yaml file based namespace'
end
