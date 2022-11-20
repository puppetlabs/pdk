require 'pdk'

module PDK
  module CLI
    class FatalError < StandardError
      attr_reader :exit_code

      def initialize(msg = 'An unexpected error has occurred. Try running the command again with --debug', opts = {})
        @exit_code = opts.fetch(:exit_code, 1)
        super(msg)
      end
    end

    class ExitWithError < StandardError
      attr_reader :exit_code
      attr_reader :log_level

      def initialize(msg, opts = {})
        @exit_code = opts.fetch(:exit_code, 1)
        @log_level = opts.fetch(:log_level, :error)
        super(msg)
      end
    end
  end
end
