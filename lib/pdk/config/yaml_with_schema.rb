require 'pdk/config/json_schema_namespace'
require 'pdk/config/json_schema_setting'

module PDK
  class Config
    class YAMLWithSchema < JSONSchemaNamespace
      def parse_file(filename)
        data = load_data(filename)
        data = '' if data.nil?
        require 'yaml'

        @raw_data = ::YAML.safe_load(data, [Symbol], [], true)
        @raw_data = {} if @raw_data.nil?

        schema_property_names.each do |key|
          yield key, PDK::Config::JSONSchemaSetting.new(key, self, @raw_data[key])
        end

        # Remove all of the "known" settings from the schema and
        # we're left with the settings that we don't manage.
        assign_unmanaged_settings(@raw_data.reject { |k, _| schema_property_names.include?(k) })
      rescue Psych::SyntaxError => e
        raise PDK::Config::LoadError, _('Syntax error when loading %{file}: %{error}') % {
          file:  filename,
          error: "#{e.problem} #{e.context}",
        }
      rescue Psych::DisallowedClass => e
        raise PDK::Config::LoadError, _('Unsupported class in %{file}: %{error}') % {
          file:  filename,
          error: e.message,
        }
      end

      def serialize_data(data)
        require 'yaml'
        ::YAML.dump(data)
      end
    end
  end
end
