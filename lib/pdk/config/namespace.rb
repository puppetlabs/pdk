require 'pdk'

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
        @file = PDK::Util::Filesystem.expand_path(file) unless file.nil?
        @settings = {}
        @name = name.to_s
        @parent = parent
        @persistent_defaults = persistent_defaults
        @mounts = {}
        @loaded_from_file = false
        @read_only = false

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
      def setting(key, &block)
        @settings[key.to_s] ||= default_setting_class.new(key.to_s, self)
        @settings[key.to_s].instance_eval(&block) if block_given?
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
        raise ArgumentError, 'Only PDK::Config::Namespace objects can be mounted into a namespace' unless obj.is_a?(PDK::Config::Namespace)
        obj.parent = self
        obj.name = key.to_s
        obj.instance_eval(&block) if block_given?
        @mounts[key.to_s] = obj
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
        # Check if it's a mount first...
        return @mounts[key.to_s] unless @mounts[key.to_s].nil?
        # Check if it's a setting, otherwise nil
        return nil if settings[key.to_s].nil?
        return settings[key.to_s].value unless settings[key.to_s].value.nil?
        # Duplicate arrays and hashes so that they are isolated from changes being made
        default_value = PDK::Util.deep_duplicate(settings[key.to_s].default)
        return default_value if default_value.nil? || !@persistent_defaults
        # Persist the default value
        settings[key.to_s].value = default_value
        save_data
        default_value
      end

      # Get the value of the named key or the provided default value if not
      # present. Note that this does not trigger persistent defaults
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
        # Check if it's a mount first...
        return @mounts[key.to_s] unless @mounts[key.to_s].nil?
        # Check if it's a setting, otherwise default_value
        return default_value if settings[key.to_s].nil?
        # Check if has a value, otherwise default_value
        settings[key.to_s].value.nil? ? default_value : settings[key.to_s].value
      end

      # After the value has been set in memory, the value will then be
      # persisted to disk.
      #
      # @param key [String,Symbol] the name of the configuration value.
      # @param value [Object] the value of the configuration value.
      #
      # @return [nil]
      def []=(key, value)
        # You can't set the value of a mount
        raise ArgumentError, 'Namespace mounts can not be set a value' unless @mounts[key.to_s].nil?
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
        new_hash = {}
        settings.each_pair { |k, v| new_hash[k] = v.value }
        @mounts.each_pair { |k, mount_point| new_hash[k] = mount_point.to_h if mount_point.include_in_parent? }
        new_hash.delete_if { |_, v| v.nil? }
        new_hash
      end

      # Resolves all filtered settings, including child namespaces, fully namespaced and filling in default values.
      #
      # @param filter [String] Only resolve setting names which match the filter. See #be_resolved? for matching rules
      # @return [Hash{String => Object}] All resolved settings for example {'user.module_defaults.author' => 'johndoe'}
      def resolve(filter = nil)
        resolved = {}
        # Resolve the settings
        settings.values.each do |setting|
          setting_name = setting.qualified_name
          if be_resolved?(setting_name, filter)
            resolved[setting_name] = setting.value.nil? ? setting.default : setting.value
          end
        end
        # Resolve the mounts
        @mounts.values.each { |mount| resolved.merge!(mount.resolve(filter)) }
        resolved
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

      # Disables the namespace, and child namespaces, from writing changes to disk.
      # Typically this is only needed for unit testing.
      # @api private
      def read_only!
        @read_only = true
        @mounts.each { |_, child| child.read_only! }
      end

      private

      # Returns the object class to create settings with. Subclasses may override this to use specific setting classes
      #
      # @return [Class[PDK::Config::Setting]]
      #
      # @abstract
      # @private
      def default_setting_class
        PDK::Config::Setting
      end

      # Determines whether a setting name should be resolved using the filter
      #  Returns true when filter is nil.
      #  Returns true if the filter is exactly the same name as the setting.
      #  Returns true if the name is a sub-key of the filter e.g.
      #    Given a filter of user.module_defaults, `user.module_defaults.author` will return true, but `user.analytics.disabled` will return false.
      #
      # @param name [String] The setting name to test.
      # @param filter [String] The filter used to test on the name.
      # @return [Boolean] Whether the name passes the filter.
      def be_resolved?(name, filter = nil)
        return true if filter.nil? # If we're not filtering, this value should always be resolved
        return true if name == filter # If it's exactly the same name then it should be resolved
        name.start_with?(filter + '.') # If name is a subkey of the filter then it should be resolved
      end

      # @abstract Subclass and override {#parse_file} to implement parsing logic
      #   for a particular config file format.
      #
      # @param data [String] The content of the file to be parsed.
      # @param filename [String] The path to the file to be parsed.
      #
      # @yield [String, Object] the data to be loaded into the
      #   namespace.
      def parse_file(_filename); end

      # @abstract Subclass and override {#serialize_data} to implement generating
      #   logic for a particular config file format.
      #
      # @param data [Hash{String => Object}] the data stored in the namespace
      #
      # @return [String] the serialized contents of the namespace suitable for
      #   writing to disk.
      def serialize_data(_data); end

      # @abstract Subclass and override {#create_missing_setting} to implement logic
      # when a setting is dynamically created, for example when attempting to
      # set the value of an unknown setting
      #
      # @param data [Hash{String => Object}] the data stored in the namespace
      #
      # @return [String] the serialized contents of the namespace suitable for
      #   writing to disk.
      def create_missing_setting(key, initial_value = nil)
        # Need to use `@settings` and `@mounts` here to stop recursive calls
        return unless @mounts[key.to_s].nil?
        return unless @settings[key.to_s].nil?
        @settings[key.to_s] = default_setting_class.new(key.to_s, self, initial_value)
      end

      # Set the value of the named key.
      #
      # If the key has been pre-configured with {#value}, then the value of the
      # key will be validated against any validators that have been configured.
      #
      # @param key [String,Symbol] the name of the configuration value.
      # @param value [Object] the value of the configuration value.
      def set_volatile_value(key, value)
        # Need to use `settings` here to force the backing file to be loaded
        return create_missing_setting(key, value) if settings[key.to_s].nil?
        # Need to use `@settings` here to stop recursive calls from []=
        @settings[key.to_s].value = value
      end

      # Helper method to read files.
      #
      # @raise [PDK::Config::LoadError] if the file is removed during read.
      # @raise [PDK::Config::LoadError] if the user doesn't have the
      #   permissions needed to read the file.
      # @return [String,nil] the contents of the file or nil if the file does
      #   not exist.
      def load_data(filename)
        return if filename.nil?
        return unless PDK::Util::Filesystem.file?(filename)

        PDK::Util::Filesystem.read_file(filename)
      rescue Errno::ENOENT => e
        raise PDK::Config::LoadError, e.message
      rescue Errno::EACCES
        raise PDK::Config::LoadError, 'Unable to open %{file} for reading' % {
          file: filename,
        }
      end

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
        return if file.nil? || @read_only

        PDK::Util::Filesystem.mkdir_p(File.dirname(file))

        PDK::Util::Filesystem.write_file(file, serialize_data(to_h))
      rescue Errno::EACCES
        raise PDK::Config::LoadError, 'Unable to open %{file} for writing' % {
          file: file,
        }
      rescue SystemCallError => e
        raise PDK::Config::LoadError, e.message
      end

      # Memoised accessor for the loaded data.
      #
      # @return [Hash<String => PDK::Config::Setting>] the contents of the namespace.
      def settings
        return @settings if @loaded_from_file
        @loaded_from_file = true
        return @settings if file.nil?
        parse_file(file) do |key, parsed_setting|
          # Create a settings chain if a setting already exists
          parsed_setting.previous_setting = @settings[key] unless @settings[key].nil?
          @settings[key] = parsed_setting
        end
        @settings
      end
    end
  end
end
