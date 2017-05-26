require 'pdk'
require 'pdk/cli/exec'

module PDK
  module Test
    class Unit
      def self.cmd(_tests)
        # TODO: actually run the tests
        # cmd = 'rake spec'
        # cmd += " #{tests}" if tests
        cmd = 'pwd'
        cmd
      end

      def self.invoke(tests, report = nil)
        output = PDK::CLI::Exec.execute(cmd(tests))
        report.write(output) if report
      end
    end
  end
end
