require 'pdk'

module PDK
  class Config
    # Parses a YAML document with a JSON schema.
    #
    # @see PDK::Config::Namespace.parse_file
    class YAMLWithSchema < JSONSchemaNamespace
      def parse_file(filename)
        raise unless block_given?
        data = load_data(filename)
        data = '' if data.nil?
        require 'yaml'
        require 'json-schema'

        @raw_data = ::YAML.safe_load(data, [Symbol], [], true)
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

        require 'pdk/config/json_schema_setting'

        schema_property_names.each do |key|
          yield key, PDK::Config::JSONSchemaSetting.new(key, self, @raw_data[key])
        end

        # Remove all of the "known" settings from the schema and
        # we're left with the settings that we don't manage.
        self.unmanaged_settings = @raw_data.reject { |k, _| schema_property_names.include?(k) }
      rescue Psych::SyntaxError => e
        raise PDK::Config::LoadError, 'Syntax error when loading %{file}: %{error}' % {
          file:  filename,
          error: "#{e.problem} #{e.context}",
        }
      rescue Psych::DisallowedClass => e
        raise PDK::Config::LoadError, 'Unsupported class in %{file}: %{error}' % {
          file:  filename,
          error: e.message,
        }
      end

      # Serializes object data into a YAML string.
      #
      # @see PDK::Config::Namespace.serialize_data
      def serialize_data(data)
        require 'yaml'
        ::YAML.dump(data)
      end
    end
  end
end
