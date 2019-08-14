module PDK
  class Config
    class Namespace
      # @param value [String] the new name of this namespace.
      attr_writer :name

      # @return [String] the path to the file associated with the contents of
      #   this namespace.
      attr_reader :file

      # @return [self] the parent namespace of this namespace.
      attr_accessor :parent

      # Initialises the PDK::Config::Namespace object.
      #
      # @param name [String] the name of the namespace (defaults to nil).
      # @param params [Hash{Symbol => Object}] keyword parameters for the
      #   method.
      # @option params [String] :file the path to the file associated with the
      #   contents of the namespace (defaults to nil).
      # @option params [self] :parent the parent {self} that this namespace is
      #   a child of (defaults to nil).
      # @option params [self] :persistent_defaults whether default values should be persisted
      #   to disk when evaluated. By default they are not persisted to disk. This is typically
      #   used for settings which a randomly generated, instead of being deterministic, e.g. analytics user-id
      # @param block [Proc] a block that is evaluated within the new instance.
      def initialize(name = nil, file: nil, parent: nil, persistent_defaults: false, &block)
        @file = File.expand_path(file) unless file.nil?
        @values = {}
        @name = name.to_s
        @parent = parent
        @persistent_defaults = persistent_defaults

        instance_eval(&block) if block_given?
      end

      # Pre-configure a value in the namespace.
      #
      # Allows you to specify validators and a default value for value in the
      # namespace (see PDK::Config::Value#initialize).
      #
      # @param key [String,Symbol] the name of the value.
      # @param block [Proc] a block that is evaluated within the new [self].
      #
      # @return [nil]
      def value(key, &block)
        @values[key.to_s] ||= PDK::Config::Value.new(key.to_s)
        @values[key.to_s].instance_eval(&block) if block_given?
      end

      # Mount a provided [self] (or subclass) into the namespace.
      #
      # @param key [String,Symbol] the name of the namespace to be mounted.
      # @param obj [self] the namespace to be mounted.
      # @param block [Proc] a block to be evaluated within the instance of the
      #   newly mounted namespace.
      #
      # @raise [ArgumentError] if the object to be mounted is not a {self} or
      #   subclass thereof.
      #
      # @return [self] the mounted namespace.
      def mount(key, obj, &block)
        raise ArgumentError, _('Only PDK::Config::Namespace objects can be mounted into a namespace') unless obj.is_a?(PDK::Config::Namespace)
        obj.parent = self
        obj.name = key.to_s
        obj.instance_eval(&block) if block_given?
        data[key.to_s] = obj
      end

      # Create and mount a new child namespace.
      #
      # @param name [String,Symbol] the name of the new namespace.
      # @param block [Proc]
      def namespace(name, &block)
        mount(name, PDK::Config::Namespace.new, &block)
      end

      # Get the value of the named key.
      #
      # If there is a value for that key, return it. If not, follow the logic
      # described in {#default_config_value} to determine the default value to
      # return.
      #
      # @note Unlike a Ruby Hash, this will not return `nil` in the event that
      #   the key does not exist (see #fetch).
      #
      # @param key [String,Symbol] the name of the value to retrieve.
      #
      # @return [Object] the requested value.
      def [](key)
        data[key.to_s]
      end

      # Get the value of the named key or the provided default value if not
      # present.
      #
      # This differs from {#[]} in an important way in that it allows you to
      # return a default value, which is not possible using `[] || default` as
      # non-existent values when accessed normally via {#[]} will be defaulted
      # to a new Hash.
      #
      # @param key [String,Symbol] the name of the value to fetch.
      # @param default_value [Object] the value to return if the namespace does
      #   not contain the requested value.
      #
      # @return [Object] the requested value.
      def fetch(key, default_value)
        data.fetch(key.to_s, default_value)
      end

      # After the value has been set in memory, the value will then be
      # persisted to disk.
      #
      # @param key [String,Symbol] the name of the configuration value.
      # @param value [Object] the value of the configuration value.
      #
      # @return [nil]
      def []=(key, value)
        set_volatile_value(key, value)
        # Persist the change
        save_data
      end

      # Convert the namespace into a Hash of values, suitable for serialising
      # and persisting to disk.
      #
      # Child namespaces that are associated with their own files are excluded
      # from the Hash (as their values will be persisted to their own files)
      # and nil values are removed from the Hash.
      #
      # @return [Hash{String => Object}] the values from the namespace that
      #   should be persisted to disk.
      def to_h
        data.inject({}) do |new_hash, (key, value)|
          new_hash[key] = if value.is_a?(PDK::Config::Namespace)
                            value.include_in_parent? ? value.to_h : nil
                          else
                            value
                          end
          new_hash.delete_if { |_, v| v.nil? }
        end
      end

      # @return [Boolean] true if the namespace has a parent, otherwise false.
      def child_namespace?
        !parent.nil?
      end

      # Determines the fully qualified name of the namespace.
      #
      # If this is a child namespace, then fully qualified name for the
      # namespace will be "<parent>.<child>".
      #
      # @return [String] the fully qualifed name of the namespace.
      def name
        child_namespace? ? [parent.name, @name].join('.') : @name
      end

      # Determines if the contents of the namespace should be included in the
      # parent namespace when persisting to disk.
      #
      # If the namespace has been mounted into a parent namespace and is not
      # associated with its own file on disk, then the values in the namespace
      # should be included in the parent namespace when persisting to disk.
      #
      # @return [Boolean] true if the values should be included in the parent
      #   namespace.
      def include_in_parent?
        child_namespace? && file.nil?
      end

      private

      # @abstract Subclass and override {#parse_data} to implement parsing logic
      #   for a particular config file format.
      #
      # @param data [String] The content of the file to be parsed.
      # @param filename [String] The path to the file to be parsed.
      #
      # @return [Hash{String => Object}] the data to be loaded into the
      #   namespace.
      def parse_data(_data, _filename)
        {}
      end

      # Set the value of the named key.
      #
      # If the key has been pre-configured with {#value}, then the value of the
      # key will be validated against any validators that have been configured.
      #
      # @param key [String,Symbol] the name of the configuration value.
      # @param value [Object] the value of the configuration value.
      def set_volatile_value(key, value)
        @values[key.to_s].validate!([name, key.to_s].join('.'), value) if @values.key?(key.to_s)

        data[key.to_s] = value
      end

      # Read the file associated with the namespace.
      #
      # @raise [PDK::Config::LoadError] if the file is removed during read.
      # @raise [PDK::Config::LoadError] if the user doesn't have the
      #   permissions needed to read the file.
      # @return [String,nil] the contents of the file or nil if the file does
      #   not exist.
      def load_data
        return if file.nil?
        return unless PDK::Util::Filesystem.file?(file)

        PDK::Util::Filesystem.read_file(file)
      rescue Errno::ENOENT => e
        raise PDK::Config::LoadError, e.message
      rescue Errno::EACCES
        raise PDK::Config::LoadError, _('Unable to open %{file} for reading') % {
          file: file,
        }
      end

      # @abstract Subclass and override {#save_data} to implement generating
      #   logic for a particular config file format.
      #
      # @param data [Hash{String => Object}] the data stored in the namespace
      #
      # @return [String] the serialized contents of the namespace suitable for
      #   writing to disk.
      def serialize_data(_data); end

      # Persist the contents of the namespace to disk.
      #
      # Directories will be automatically created and the contents of the
      # namespace will be serialized automatically with {#serialize_data}.
      #
      # @raise [PDK::Config::LoadError] if one of the intermediary path components
      #   exist but is not a directory.
      # @raise [PDK::Config::LoadError] if the user does not have the
      #   permissions needed to write the file.
      #
      # @return [nil]
      def save_data
        return if file.nil?

        PDK::Util::Filesystem.mkdir_p(File.dirname(file))

        PDK::Util::Filesystem.write_file(file, serialize_data(to_h))
      rescue Errno::EACCES
        raise PDK::Config::LoadError, _('Unable to open %{file} for writing') % {
          file: file,
        }
      rescue SystemCallError => e
        raise PDK::Config::LoadError, e.message
      end

      # Memoised accessor for the loaded data.
      #
      # @return [Hash<String => Object>] the contents of the namespace.
      def data
        # It's possible for parse_data to return nil, so just return an empty hash
        @data ||= parse_data(load_data, file).tap do |h|
          h.default_proc = default_config_value unless h.nil?
        end || {}
      end

      # The default behaviour of the namespace when the requested value does
      # not exist.
      #
      # If the value has been pre-configured with {#value} to have a default
      # value, resolve the default value and set it in the namespace and optionally
      # save the new default.
      # Otherwise, set the value to a new Hash to allow for arbitrary level of nested values.
      #
      # @return [Proc] suitable for use by {Hash#default_proc}.
      def default_config_value
        ->(hash, key) do
          if @values.key?(key) && @values[key].default?
            set_volatile_value(key, @values[key].default)
            save_data if @persistent_defaults
            hash[key]
          else
            hash[key] = {}.tap do |h|
              h.default_proc = default_config_value
            end
          end
        end
      end
    end
  end
end
