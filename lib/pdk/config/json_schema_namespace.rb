require 'pdk'

# Due to https://github.com/ruby-json-schema/json-schema/issues/439
# Windows file paths "appear" as uri's with no host and a schema of drive letter
# Also it is not possible to craft a URI with a Windows path due to the URI object
# always prepending the path with forward slash (`/`) so Windows paths end up looking
# like '/C:\schema.json', which can not be read.
# Instead we need to monkey patch the Schema Reader reader to remove the errant forward slash
require 'json-schema/schema/reader'
module JSON
  class Schema
    class Reader
      alias original_read_file read_file

      def read_file(pathname)
        new_pathname = JSON::Util::URI.unescaped_path(pathname.to_s)
        # Munge the path if it looks like a Windows path e.g. /C:/Windows ...
        # Note that UNC style paths do not have the same issue (\\host\path)
        new_pathname.slice!(0) if new_pathname.start_with?('/') && new_pathname[2] == ':'
        original_read_file(Pathname.new(new_pathname))
      end
    end
  end
end

require 'json-schema'

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
        raise ArgumentError, "Setting '#{key}' does not exist'"
      end

      # Create a valid, but empty schema
      #
      # @return [JSON::Schema]
      def create_empty_schema
        ::JSON::Schema.new({}, 'http://json-schema.org/draft-06/schema#')
      end

      # Lazily retrieve the JSON schema from disk for this namespace
      #
      # @return [JSON::Schema]
      def document_schema
        return @document_schema unless @document_schema.nil?

        # Create an empty schema by default.
        @document_schema = create_empty_schema

        return @document_schema if @schema_file.nil?
        unless PDK::Util::Filesystem.file?(@schema_file)
          raise PDK::Config::LoadError, 'Unable to open %{file} for reading. File does not exist' % {
            file: @schema_file,
          }
        end

        # The schema should not query external URI references, except for the meta-schema. Local files are allowed
        schema_reader = ::JSON::Schema::Reader.new(
          accept_file: true,
          accept_uri:  proc { |uri| uri.host.nil? || ['json-schema.org'].include?(uri.host) },
        )
        @document_schema = schema_reader.read(Addressable::URI.convert_path(@schema_file))
      rescue ::JSON::Schema::JsonParseError => e
        raise PDK::Config::LoadError, 'Unable to open %{file} for reading. JSON Error: %{msg}' % {
          file: @schema_file,
          msg: e.message,
        }
      end
    end
  end
end
