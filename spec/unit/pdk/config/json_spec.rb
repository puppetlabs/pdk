require 'spec_helper'
require 'tempfile'
require 'pdk/config/json'

describe PDK::Config::JSON do
  subject(:json_config) { described_class.new(file: tempfile) }

  let(:tempfile) do
    file = Tempfile.new('test')
    file.path
  end

  it_behaves_like 'a file based namespace', "{\n  \"foo\": \"bar\"\n}", 'foo' => 'bar'

  it_behaves_like 'a file based namespace without a schema'

  it_behaves_like 'a json file based namespace'
end
