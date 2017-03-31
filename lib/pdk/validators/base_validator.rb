require 'pdk'
require 'pdk/cli/exec'

module PDK
  module Validate
    class BaseValidator
      def self.invoke(report = nil, options = {})
        PDK.logger.info("Running #{cmd} with options: #{options}")
        output = PDK::CLI::Exec.execute(cmd, options)
        report.write(output) if report
      end
    end
  end
end
