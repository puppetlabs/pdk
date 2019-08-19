require 'pdk/config/namespace'

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

        # The schema should not query external URI references, except for the meta-schema. Local files are allowed
        schema_reader = ::JSON::Schema::Reader.new(
          accept_file: true,
          accept_uri:  proc { |uri| uri.host.nil? || ['json-schema.org'].include?(uri.host) },
        )
        @document_schema = schema_reader.read(Addressable::URI.convert_path(@schema_file))
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
