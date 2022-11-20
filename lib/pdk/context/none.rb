require 'pdk'

module PDK
  module Context
    # Represents a context which the PDK does not know. For example
    # an empty directory
    class None < PDK::Context::AbstractContext
      #:nocov:
      # @see PDK::Context::AbstractContext.display_name
      def display_name
        'an unknown context'
      end
      #:nocov:

      # @see PDK::Context::AbstractContext.parent_context
      def parent_context
        # An unknown context has no parent
        nil
      end
    end
  end
end
