require 'pdk/config/json_schema_namespace'
require 'pdk/config/json_schema_setting'

module PDK
  class Config
    class JSONWithSchema < JSONSchemaNamespace
      def parse_file(filename)
        data = load_data(filename)
        data = '{}' if data.nil? || data.empty?
        require 'json'

        @raw_data = ::JSON.parse(data)
        @raw_data = {} if @raw_data.nil?

        schema_property_names.each do |key|
          yield key, PDK::Config::JSONSchemaSetting.new(key, self, @raw_data[key])
        end

        # Remove all of the "known" settings from the schema and
        # we're left with the settings that we don't manage.
        assign_unmanaged_settings(@raw_data.reject { |k, _| schema_property_names.include?(k) })
      rescue ::JSON::ParserError => e
        raise PDK::Config::LoadError, e.message
      end

      def serialize_data(data)
        require 'json'

        ::JSON.pretty_generate(data)
      end
    end
  end
end
