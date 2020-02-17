require 'pdk'

module PDK
  module Context
    # Represents a context for a directory based Control Repository
    class ControlRepo < PDK::Context::AbstractContext
      # @param repo_root [String] The root path for the control repo.
      # @param context_path [String] The path where this context was created from e.g. Dir.pwd
      # @see PDK::Context::AbstractContext
      def initialize(repo_root, context_path)
        super(context_path)
        @root_path = repo_root
      end

      def pdk_compatible?
        # Currently there is nothing to determine compatibility with the PDK for a
        # Control Repo. For now assume everything is compatible
        true
      end

      #:nocov:
      # @see PDK::Context::AbstractContext.display_name
      def display_name
        _('a Control Repository context')
      end
      #:nocov:
    end
  end
end
