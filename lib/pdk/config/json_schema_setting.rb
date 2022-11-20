require 'pdk'

module PDK
  class Config
    class JSONSchemaSetting < PDK::Config::Setting
      # Initialises the PDK::Config::JSONSchemaSetting object.
      #
      # @see PDK::Config::Setting.initialize
      def initialize(_name, namespace, _initial_value)
        raise 'The JSONSchemaSetting object can only be created within the JSONSchemaNamespace' unless namespace.is_a?(PDK::Config::JSONSchemaNamespace)
        super
      end

      # Verifies that the new setting value is valid by calling the JSON schema validator on
      # a hash which includes the new setting
      #
      # @see PDK::Config::Setting.validate!
      def validate!(value)
        # Get the existing namespace data
        new_document = namespace.to_h
        # ... set the new value
        new_document[@name] = value
        begin
          # ... add validate it
          namespace.validate_document!(new_document)
        rescue ::JSON::Schema::ValidationError => e
          raise ArgumentError, '%{key} %{message}' % {
            key:     qualified_name,
            message: e.message,
          }
        end
      end

      # Evaluate the default setting, firstly from the JSON schema and then
      # from any other default evaluators in the settings chain.
      #
      # @see PDK::Config::Setting.default
      #
      # @return [Object, nil] the result of evaluating the block given to
      #   {#default_to}, or `nil` if the setting has no default.
      def default
        # Return the default from the schema document if it exists
        if namespace.schema_property_names.include?(@name)
          prop_schema = namespace.schema['properties'][@name]
          return prop_schema['default'] unless prop_schema['default'].nil?
        end
        # ... otherwise call the settings chain default
        # and if that doesn't exist, just return nil
        @previous_setting.nil? ? nil : @previous_setting.default
      end
    end
  end
end
