require 'pdk/config/namespace'

module PDK
  class Config
    class JSONSchemaNamespace < Namespace
      # Initialises the PDK::Config::JSONSchemaNamespace object.
      #
      # @see PDK::Config::Namespace.initialize
      #
      # @option params [self] :schema_file TODO
      def initialize(name = nil, file: nil, parent: nil, persistent_defaults: false, schema_file: nil, &block)
        super(name, file: file, parent: parent, persistent_defaults: persistent_defaults, &block)
        @schema_file = schema_file
      end

      def schema
        document_schema.schema
      end

      def empty_schema?
        document_schema.schema.empty?
      end

      def schema_property_names
        return [] if schema['properties'].nil?
        schema['properties'].keys
      end

      def to_h
        # This may seem counter-intuitive but we need to call super first as the settings
        # may not have been loaded yet, which means @unmanaged_settings will be empty.
        # We call super first to force any file loading and then merge the unmanaged settings
        settings_hash = super
        @unmanaged_settings = {} if @unmanaged_settings.nil?
        @unmanaged_settings.merge(settings_hash)
      end

      # @private
      def assign_unmanaged_settings(value)
        @unmanaged_settings = value
      end

      private

      # Override the create_setting method to always fail. This is called
      # to dyanmically add settings. However as we're using a schema, no
      # new settings can be created
      def create_missing_setting(key, _initial_value = nil)
        raise ArgumentError, _("Setting '#{key}' does not exist'")
      end

      def create_empty_schema
        require 'json-schema'
        ::JSON::Schema.new({}, 'http://json-schema.org/draft-06/schema#')
      end

      def document_schema
        return @document_schema unless @document_schema.nil?

        require 'json-schema'

        if @schema_file.nil?
          @document_schema = create_empty_schema
          return @document_schema
        end
        unless PDK::Util::Filesystem.file?(@schema_file)
          # TODO: Raise error?
          @document_schema = create_empty_schema
          return @document_schema
        end

        # The schema should not query external references, except for the meta-schema
        schema_reader = ::JSON::Schema::Reader.new(
          accept_file: false,
          accept_uri:  proc { |uri| uri.host.nil? || ['json-schema.org'].include?(uri.host) },
        )
        @document_schema = schema_reader.read(@schema_file)
      rescue ::JSON::Schema::JsonParseError => e
        @document_schema = create_empty_schema
        raise PDK::Config::LoadError, _('Unable to open %{file} for reading. JSON Error: %{msg}') % {
          file: @schema_file,
          msg: e.message,
        }
      end
    end
  end
end
