require 'pdk'
require 'pdk/cli/exec'
require 'pdk/util/bundler'

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
        PDK::Util::Bundler.ensure_bundle!

        puts _('Running unit tests: %{tests}') % { tests: tests }

        output = PDK::CLI::Exec.execute(cmd(tests))
        report.write(output) if report
      end
    end
  end
end
