require 'spec_helper'
require 'pdk/config/yaml_with_schema'
require 'tempfile'

# Note that the JSON Schema Gem is too unreliable for testing right now.
# For the moment, all tests are skipped here.
describe PDK::Config::YAMLWithSchema, :skip do
  subject(:yaml_config) { described_class.new(file: tempfile, schema_file: temp_schema_file) }

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

  it_behaves_like 'a file based namespace', "---\nfoo: bar\n", { 'foo' => 'bar' }, true

  it_behaves_like 'a file based namespace with a schema', "---\nextra_setting: \"extra value\"\nfoo: oldvalue"

  it_behaves_like 'a yaml file based namespace'

  it 'inherits from JSONSchemaNamespace' do
    expect(yaml_config).to be_a(PDK::Config::JSONSchemaNamespace)
  end
end
