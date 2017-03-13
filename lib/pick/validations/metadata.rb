require 'pick'
require 'pick/cli/exec'

module Pick
  module Validate
    class Metadata
      def self.cmd
        'metadata-json-lint'
      end

      def self.invoke(report = nil)
        output = Pick::CLI::Exec.execute(cmd)
        report.write(output) if report
      end
    end
  end
end
