require 'pick'
require 'pick/cli/exec'

module Pick
  module Validate
    class PuppetLint
      def self.cmd
        'puppet-lint'
      end

      def self.invoke(report = nil)
        output = Pick::CLI::Exec.execute(cmd)
        report.write(output) if report
      end
    end
  end
end
