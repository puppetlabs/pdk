require 'pdk/config/namespace'

module PDK
  class Config
    class JSONSchemaNamespace < Namespace
      # Initialises the PDK::Config::JSONSchemaNamespace object.
      #
      # @see PDK::Config::Namespace.initialize
      #
      # @option params [String] :schema_file Path to the JSON Schema document
      def initialize(name = nil, file: nil, parent: nil, persistent_defaults: false, schema_file: nil, &block)
        super(name, file: file, parent: parent, persistent_defaults: persistent_defaults, &block)
        @schema_file = schema_file
        @unmanaged_settings = {}
      end

      # The JSON Schema for the namespace
      #
      # @return [Hash]
      def schema
        document_schema.schema
      end

      # Whether the schema is valid but empty.
      #
      # @return [Boolean]
      def empty_schema?
        document_schema.schema.empty?
      end

      # Name of all the top level properties for the schema
      #
      # @return [String[]]
      def schema_property_names
        return [] if schema['properties'].nil?
        schema['properties'].keys
      end

      # Extends the to_h namespace method to include unmanaged settings
      #
      # @see PDK::Config::Namespace.to_h
      def to_h
        # This may seem counter-intuitive but we need to call super first as the settings
        # may not have been loaded yet, which means @unmanaged_settings will be empty.
        # We call super first to force any file loading and then merge the unmanaged settings
        settings_hash = super
        @unmanaged_settings = {} if @unmanaged_settings.nil?
        @unmanaged_settings.merge(settings_hash)
      end

      # Validates a document (Hash table) against the schema
      #
      # @return [Boolean]
      def validate_document!(document)
        ::JSON::Validator.validate!(schema, document)
      end

      protected

      # @!attribute [w] unmanaged_settings
      #   Sets the list of unmanaged settings. For subclass use only
      #
      #   @param unmanaged_settings [Hash<String, Object]] A hashtable of all unmanaged settings which will be persisted, but not visible
      #   @protected
      attr_writer :unmanaged_settings

      private

      # Override the create_setting method to always fail. This is called
      # to dyanmically add settings. However as we're using a schema, no
      # new settings can be created
      #
      # @see PDK::Config::Namespace.create_missing_setting
      #
      # @private
      def create_missing_setting(key, _initial_value = nil)
        raise ArgumentError, _("Setting '#{key}' does not exist'")
      end

      # Create a valid, but empty schema
      #
      # @return [JSON::Schema]
      def create_empty_schema
        require 'json-schema'
        ::JSON::Schema.new({}, 'http://json-schema.org/draft-06/schema#')
      end

      # Lazily retrieve the JSON schema from disk for this namespace
      #
      # @return [JSON::Schema]
      def document_schema
        return @document_schema unless @document_schema.nil?

        # Create an empty schema by default.
        @document_schema = create_empty_schema

        require 'json-schema'

        return @document_schema if @schema_file.nil?
        unless PDK::Util::Filesystem.file?(@schema_file)
          raise PDK::Config::LoadError, _('Unable to open %{file} for reading. File does not exist') % {
            file: @schema_file,
          }
        end

        # The schema should not query external references, except for the meta-schema
        schema_reader = ::JSON::Schema::Reader.new(
          accept_file: false,
          accept_uri:  proc { |uri| uri.host.nil? || ['json-schema.org'].include?(uri.host) },
        )
        @document_schema = schema_reader.read(@schema_file)
      rescue ::JSON::Schema::JsonParseError => e
        raise PDK::Config::LoadError, _('Unable to open %{file} for reading. JSON Error: %{msg}') % {
          file: @schema_file,
          msg: e.message,
        }
      end
    end
  end
end
