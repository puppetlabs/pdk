require 'pdk'

module PDK
  module Context
    autoload :None, 'pdk/context/none'
    autoload :Module, 'pdk/context/module'
    autoload :ControlRepo, 'pdk/context/control_repo'

    # Automatically determines the PDK Context given a path. Create will continue up the directory tree until it
    # finds a valid context
    # @return [PDK::Context::AbstractContext] Returns a PDK::Context::None if the context could not be determined
    def self.create(context_path)
      return PDK::Context::None.new(context_path) unless PDK::Util::Filesystem.directory?(context_path)

      previous = nil
      current = PDK::Util::Filesystem.expand_path(context_path)
      until !PDK::Util::Filesystem.directory?(current) || current == previous
        # Control Repo detection
        return PDK::Context::ControlRepo.new(current, context_path) if PDK.feature_flag?('controlrepo') && PDK::ControlRepo.control_repo_root?(current)

        # Puppet Module detection
        metadata_file = File.join(current, 'metadata.json')
        if PDK::Util::Filesystem.file?(metadata_file) || PDK::Util.in_module_root?(context_path)
          return PDK::Context::Module.new(current, context_path)
        end

        previous = current
        current = PDK::Util::Filesystem.expand_path('..', current)
      end
      PDK::Context::None.new(context_path)
    end

    # Abstract class which all PDK Contexts will subclass from.
    # @abstract
    class AbstractContext
      # The root of this context, for example the module root when inside a module. This can be different from context_path
      # For example a Module context_path could be /path/to/module/manifests/ but the root_path will be /path/to/module as
      # that is the root of the Module context. Defaults to the context_path if not set.
      # @return [String]
      def root_path
        @root_path || @context_path
      end

      # The path used to create this context, for example the current working directory. This can be different from root_path
      # For example a Module context_path could be /path/to/module/manifests/ but the root_path will be /path/to/module as
      # that is the root of the Module context
      # @return [String]
      attr_reader :context_path

      # @param context_path [String] The path where this context was created from e.g. Dir.pwd
      def initialize(context_path)
        @context_path = context_path
        @root_path = nil
      end

      # Whether the current context is compatible with the PDK e.g. in a Module context, whether it has the correct metadata.json content
      # @return [Boolean] Default is not compatible
      def pdk_compatible?
        false
      end

      # The friendly name to display for this context
      # @api private
      # @abstract
      def display_name; end

      # The context which this context is in.  For example a Module Context (/controlrepo/site/profile) can be inside of a Control Repo context (/controlrepo)
      # The default is to search in the parent directory of this context
      # @return [PDK::Context::AbstractContext, Nil] Returns the parent context or nil if there is no parent.
      def parent_context
        # Default detection is just look for the context in the parent directory of this context
        @parent_context || PDK::Context.create(File.dirname(root_path))
      end

      # Writes the current context information, and parent contexts, to the PDK Debug Logger.
      # This is mainly used by the PDK CLI when in debug mode to assist users to figure out why the PDK is misbehaving.
      # @api private
      def to_debug_log
        current = self
        depth = 1
        loop do
          PDK.logger.debug("Detected #{current.display_name} at #{current.root_path.nil? ? current.context_path : current.root_path}")
          current = current.parent_context
          break if current.nil?
          depth += 1
          # Circuit breaker in case there are circular references
          break if depth > 20
        end
        nil
      end

      #:nocov: There's nothing to test here
      def to_s
        "#<#{self.class}:#{object_id}>#{context_path}"
      end
      #:nocov:
    end
  end
end
