require 'pdk'
require 'pdk/cli/exec'

module PDK
  module Validate
    class BaseValidator
      def self.invoke(options = {})
        PDK.logger.info(_('Running %{cmd} with options: %{options}') % { cmd: cmd, options: options })
        result = PDK::CLI::Exec.execute(cmd, options)
        result
      end
    end
  end
end
