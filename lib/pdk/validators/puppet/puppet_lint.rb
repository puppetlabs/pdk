require 'pdk'
require 'pdk/util'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'

module PDK
  module Validate
    class PuppetLint < BaseValidator
      def self.name
        'puppet-lint'
      end

      def self.cmd
        "puppet-lint"
      end

      def self.parse_options(options, targets)
        cmd_options = []

        if options[:format] && options[:format] == 'junit'
          cmd_options << '--json'
        end

        cmd_options.concat(targets)
      end
    end
  end
end
