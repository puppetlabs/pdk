require 'pdk'
require 'pdk/cli/exec'

module PDK
  module Validate
    class Metadata
      def self.cmd
        'metadata-json-lint'
      end

      def self.invoke(report = nil)
        output = PDK::CLI::Exec.execute(cmd)
        report.write(output) if report
      end
    end
  end
end
