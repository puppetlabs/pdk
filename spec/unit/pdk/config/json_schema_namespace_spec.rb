require 'spec_helper'
require 'pdk/config/json_schema_namespace'

def load_and_ignore(namespace)
  namespace.schema
rescue StandardError # rubocop:disable Lint/HandleExceptions In this I don't want to handle the error
  # Do nothing
end

describe PDK::Config::JSONSchemaNamespace do
  subject(:namespace) { described_class.new('spec', schema_file: temp_schema_file) }

  let(:temp_schema_file) do
    file = Tempfile.new('schema')
    file.write(schema_data)
    file.close
    file.path
  end

  context 'with a valid schema' do
    let(:setting_name) { 'a_setting' }
    let(:schema_data) do
      <<-SCHEMA
      {
        "definitions": {},
        "$schema": "http://json-schema.org/draft-04/schema#",
        "$id": "http://puppet.com/schema/does_not_exist.json",
        "type": "object",
        "title": "A Schema",
        "properties": {
          "#{setting_name}": {
            "$id": "#/properties/properties",
            "type": "boolean",
            "title": "A property",
            "examples": [
              false
            ]
          }
        }
      }
      SCHEMA
    end

    describe '#schema' do
      it 'returns the schema definition' do
        expect(namespace.schema).not_to be_empty
        expect(namespace.schema['title']).to eq('A Schema')
        expect(namespace.schema['properties']).not_to be_nil
      end
    end

    describe '#empty_schema?' do
      it 'is false' do
        expect(namespace.empty_schema?).to be false
      end
    end

    describe '#schema_property_names' do
      it 'is the same as the schema document' do
        expect(namespace.schema_property_names).to eq([setting_name])
      end
    end

    describe '#to_h' do
      context 'with an unmanaged setting' do
        before(:each) do
          # Mimic an unmanaged setting, that is, a setting not in the schema
          # TODO: Perhaps we should subclass here instead of using instance_variable_set ?
          namespace.instance_variable_set(:@unmanaged_settings, 'extra_setting' => 'extra_value')
        end

        context 'when no settings are being managed by the schema' do
          let(:schema_data) do
            <<-SCHEMA
            {
              "definitions": {},
              "$schema": "http://json-schema.org/draft-05/schema#",
              "$id": "http://puppet.com/schema/does_not_exist.json",
              "type": "object",
              "title": "A Schema",
              "properties": {
              }
            }
            SCHEMA
          end

          it 'only emits unmanaged settings' do
            expect(namespace.to_h).to eq('extra_setting' => 'extra_value')
          end
        end

        it 'emits managed and unmanaged settings' do
          # Create a fake setting, as if it was loaded from the file
          namespace.setting(setting_name)
          namespace[setting_name] = 'foo'
          expect(namespace.to_h).to eq('extra_setting' => 'extra_value', 'a_setting' => 'foo')
        end
      end
    end
  end

  context 'with a valid schema with no properties' do
    let(:schema_data) do
      <<-SCHEMA
      {
        "definitions": {},
        "$schema": "http://json-schema.org/draft-04/schema#",
        "$id": "http://puppet.com/schema/does_not_exist.json",
        "type": "object",
        "title": "A propertyless Schema"
      }
      SCHEMA
    end

    describe '#empty_schema?' do
      it 'is false' do
        expect(namespace.empty_schema?).to be false
      end
    end

    describe '#schema_property_names' do
      it 'is an empty array' do
        expect(namespace.schema_property_names).to eq([])
      end
    end
  end

  context 'with an invalid schema (Missing information)' do
    let(:schema_data) do
      <<-SCHEMA
      {
        "title": "An invalid schema"
      }
      SCHEMA
    end

    describe '#empty_schema?' do
      it 'is false' do
        expect(namespace.empty_schema?).to be false
      end
    end

    describe '#schema_property_names' do
      it 'is an empty array' do
        expect(namespace.schema_property_names).to eq([])
      end
    end
  end

  context 'with an invalid schema (Invalid syntax)' do
    let(:schema_data) do
      <<-SCHEMA
      { this is not valid JSON
      SCHEMA
    end

    describe '#schema' do
      it 'raises PDK::Config::LoadError' do
        expect { namespace.schema }.to raise_error(PDK::Config::LoadError, %r{JSON Error})
      end
    end
  end

  context 'with a schema file that does not exist' do
    let(:temp_schema_file) { 'path/that/can/not/exist/:;|' }

    it 'raises an error' do
      expect { namespace.schema }.to raise_error(PDK::Config::LoadError, %r{File does not exist})
    end

    describe '#schema' do
      it 'has a schema definition' do
        load_and_ignore(namespace)
        expect(namespace.schema).not_to be_nil
      end
    end

    describe '#empty_schema?' do
      it 'is true' do
        load_and_ignore(namespace)
        expect(namespace.empty_schema?).to be true
      end
    end

    describe '#schema_property_names' do
      it 'is empty' do
        load_and_ignore(namespace)
        expect(namespace.schema_property_names).to eq([])
      end
    end
  end

  context 'with a nil schema file path' do
    let(:temp_schema_file) { nil }

    describe '#schema' do
      it 'has a schema definition' do
        expect(namespace.schema).not_to be_nil
      end
    end

    describe '#empty_schema?' do
      it 'is true' do
        expect(namespace.empty_schema?).to be true
      end
    end

    describe '#schema_property_names' do
      it 'is empty' do
        expect(namespace.schema_property_names).to eq([])
      end
    end
  end
end
