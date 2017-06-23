module PDK
  module CLI
    module Util
      # Ensures the calling code is being run from inside a module directory.
      #
      # @raise [PDK::CLI::FatalError] if the current directory or parents do
      #   not contain a `metadata.json` file.
      def ensure_in_module!
        message = _('This command must be run from inside a module (no metadata.json found)')
        raise PDK::CLI::FatalError, message if PDK::Util.module_root.nil?
      end
      module_function :ensure_in_module!
    end
  end
end
