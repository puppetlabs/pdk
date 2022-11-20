require 'pdk'

module PDK
  module Context
    # Represents a context for a Puppet Module
    class Module < PDK::Context::AbstractContext
      # @param module_root [String] The root path for the module.
      # @param context_path [String] The path where this context was created from e.g. Dir.pwd
      # @see PDK::Context::AbstractContext
      def initialize(module_root, context_path)
        super(context_path)
        @root_path = module_root
      end

      # @see PDK::Context::AbstractContext.pdk_compatible?
      def pdk_compatible?
        PDK::Util.module_pdk_compatible?(root_path)
      end

      #:nocov:
      # @see PDK::Context::AbstractContext.display_name
      def display_name
        'a Puppet Module context'
      end
      #:nocov:
    end
  end
end
