module PDK
  module CLI
    class FatalError < StandardError
      attr_reader :exit_code

      def initialize(msg = _("An unexpected error has occurred, try running the command again with --debug"), exit_code=1)
        @exit_code = exit_code
        super(msg)
      end
    end
  end
end
