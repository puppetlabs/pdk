require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'

module PDK
  module Validate
    class PuppetParser < BaseValidator
      def self.name
        'puppet-parser'
      end

      def self.cmd
        'pwd'
      end

      def self.invoke(options = {})
        PDK.logger.info(_("Running %{cmd} with options: %{options}") % {cmd: cmd, options: options})
        result = PDK::CLI::Exec.execute(cmd)
      end
    end
  end
end
