require 'spec_helper'
require 'pdk/config/json_with_schema'
require 'tempfile'

describe PDK::Config::JSONWithSchema do
  subject(:json_config) { described_class.new(file: tempfile, schema_file: temp_schema_file) }

  let(:tempfile) do
    file = Tempfile.new('test')
    file.write(data)
    file.close
    file.path
  end
  let(:data) { nil }
  let(:temp_schema_file) do
    file = Tempfile.new('schema')
    file.write(schema_data)
    file.close
    file.path
  end

  let(:schema_data) do
    <<-SCHEMA
    {
      "definitions": {},
      "$schema": "http://json-schema.org/draft-06/schema#",
      "$id": "http://puppet.com/schema/does_not_exist.json",
      "type": "object",
      "title": "A Schema",
      "properties": {
        "foo": {
          "$id": "#/properties/foo",
          "title": "A property"
        }
      }
    }
    SCHEMA
  end

  if Gem.win_platform?
    it_behaves_like 'a file based namespace', "{\n  \"foo\": \"bar\"\n}", 'foo' => 'bar'

    it_behaves_like 'a file based namespace with a schema', "{\n\"extra_setting\": \"extra_value\",\n\"foo\": \"oldvalue\"\n}\n"

    it_behaves_like 'a json file based namespace'
  else
    skip('Tests are failing on non-Windows platforms')
  end

  it 'inherits from JSONSchemaNamespace' do
    expect(json_config).to be_a(PDK::Config::JSONSchemaNamespace)
  end
end
