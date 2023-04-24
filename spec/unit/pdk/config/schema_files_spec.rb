require 'spec_helper'
require 'pdk/config'
require 'json-schema'

describe 'PDK::Config Schema Files' do
  PDK::Util::Filesystem.glob(File.join(PDK::Config.json_schemas_path, '*_schema.json')).each do |schema_path|
    describe File.basename(schema_path) do
      # rubocop:disable PDK/FileOpen
      subject(:schema) { JSON.parse(File.open(schema_path, 'rb:UTF-8').read) }
      # rubocop:enable PDK/FileOpen

      it 'is a valid JSON schema document' do
        # The Schema Document specifies which schema version it uses
        expect(schema['$schema']).to match(/draft-\d+/)
        metaschema = JSON::Validator.validator_for_name(schema['$schema']).metaschema

        expect(JSON::Validator.validate(metaschema, schema)).to be true
      end
    end
  end
end
