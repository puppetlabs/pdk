require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'
require 'pdk/validators/ruby_validator'

module PDK
  module Validate
    class Rubocop < BaseValidator
      def self.name
        'rubocop'
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
