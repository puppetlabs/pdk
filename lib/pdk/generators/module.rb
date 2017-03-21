require 'pdk'
require 'pdk/cli/exec'

module PDK
  module Generate
    class Module
      def self.cmd(opts={})
        # TODO
        cmd = 'pwd'
        cmd
      end

      def self.invoke(opts={})
        PDK::CLI::Exec.execute(cmd(opts))
      end
    end
  end
end
