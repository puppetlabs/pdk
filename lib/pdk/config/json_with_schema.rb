require 'pdk'

module PDK
  class Config
    class JSONWithSchema < JSONSchemaNamespace
      # Parses a JSON document with a schema.
      #
      # @see PDK::Config::Namespace.parse_file
      def parse_file(filename)
        raise unless block_given?
        data = load_data(filename)
        data = '{}' if data.nil? || data.empty?
        require 'json'

        @raw_data = ::JSON.parse(data)
        @raw_data = {} if @raw_data.nil?

        begin
          # Ensure the parsed document is actually valid
          validate_document!(@raw_data)
        rescue ::JSON::Schema::ValidationError => e
          raise PDK::Config::LoadError, 'The configuration file %{filename} is not valid: %{message}' % {
            filename: filename,
            message:  e.message,
          }
        end

        schema_property_names.each do |key|
          yield key, PDK::Config::JSONSchemaSetting.new(key, self, @raw_data[key])
        end

        # Remove all of the "known" settings from the schema and
        # we're left with the settings that we don't manage.
        self.unmanaged_settings = @raw_data.reject { |k, _| schema_property_names.include?(k) }
      rescue ::JSON::ParserError => e
        raise PDK::Config::LoadError, e.message
      end

      # Serializes object data into a JSON string.
      #
      # @see PDK::Config::Namespace.serialize_data
      def serialize_data(data)
        require 'json'

        ::JSON.pretty_generate(data)
      end
    end
  end
end
