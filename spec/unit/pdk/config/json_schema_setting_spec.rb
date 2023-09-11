require 'spec_helper'
require 'pdk/config/json_schema_setting'

# Note that the JSON Schema Gem is too unreliable for testing right now.
# For the moment, all tests are skipped here.
describe PDK::Config::JSONSchemaSetting, :skip do
  subject(:setting) { described_class.new('spec_setting', namespace, initial_value) }

  let(:initial_value) { nil }

  let(:namespace) { PDK::Config::JSONSchemaNamespace.new('spec', schema_file: temp_schema_file) }

  let(:temp_schema_file) do
    file = Tempfile.new('schema')
    file.write(schema_data)
    file.close
    file.path
  end

  context 'when not in a JSON Schema Namespace' do
    let(:namespace) { PDK::Config::Namespace.new }

    it 'raises' do
      expect { setting }.to raise_error(/JSONSchemaNamespace/)
    end
  end

  context 'with a schema containing default and type information' do
    let(:schema_data) do
      <<-SCHEMA
      {
        "definitions": {},
        "$schema": "http://json-schema.org/draft-06/schema#",
        "$id": "http://puppet.com/schema/does_not_exist.json",
        "type": "object",
        "title": "A Schema",
        "properties": {
          "spec_setting": {
            "$id": "#/properties/spec_setting",
            "type": "string",
            "default": "schema_default",
            "title": "A property"
          }
        }
      }
      SCHEMA
    end

    describe '#validate!' do
      it 'does not raise with a valid value' do
        expect { setting.validate!('value') }.not_to raise_error
      end

      it 'raises with an invalid value' do
        expect { setting.validate!(123) }.to raise_error(ArgumentError, /spec_setting/)
      end
    end

    describe '#default' do
      it 'uses the default in the schema' do
        expect(setting.default).to eq('schema_default')
      end
    end
  end

  context 'with a schema not containing default or type information' do
    let(:schema_data) do
      <<-SCHEMA
      {
        "definitions": {},
        "$schema": "http://json-schema.org/draft-06/schema#",
        "$id": "http://puppet.com/schema/does_not_exist.json",
        "type": "object",
        "title": "A Schema",
        "properties": {
          "spec_setting": {
            "$id": "#/properties/spec_setting",
            "title": "A property"
          }
        }
      }
      SCHEMA
    end

    describe '#validate!' do
      it 'does not raise with any value type' do
        ['value', nil, 123, false, true, Object.new].each do |value|
          expect { setting.validate!(value) }.not_to raise_error
        end
      end
    end

    describe '#default' do
      it 'is nil' do
        expect(setting.default).to be_nil
      end
    end

    context 'with a namespace defining a default value in the definition' do
      let(:namespace) do
        PDK::Config::JSONSchemaNamespace.new('spec', schema_file: temp_schema_file) do
          setting :spec_setting do
            default_to { 'namespace_default' }
          end
        end
      end

      describe '#default' do
        it 'evaluates the default in the settings chain' do
          # The namespace doesn't expose the settings hash directly, so need to use a bit of ruby
          # magic to get the private instance variable
          previous_setting = namespace.instance_variable_get(:@settings)['spec_setting']
          setting.previous_setting = previous_setting
          expect(setting.default).to eq('namespace_default')
        end
      end
    end
  end
end
