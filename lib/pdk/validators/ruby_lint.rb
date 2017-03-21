require 'pdk'
require 'pdk/cli/exec'

module PDK
  module Validate
    class RubyLint
      def self.cmd
        'rubocop'
      end

      def self.invoke(report = nil)
        output = PDK::CLI::Exec.execute(cmd)
        report.write(output) if report
      end
    end
  end
end
