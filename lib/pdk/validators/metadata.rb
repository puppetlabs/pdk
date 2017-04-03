require 'pdk'
require 'pdk/cli/exec'

module PDK
  module Validate
    class Metadata
      def self.cmd
        'metadata-json-lint'
      end

      def self.invoke
        PDK.logger.info("Running #{cmd}")
        result = PDK::CLI::Exec.execute(cmd)

        result
      end
    end
  end
end
