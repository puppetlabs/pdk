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

      def self.parse_targets(options = {})
        targets = []

        # If no targets are passed, then we will run puppet-lint on the base
        # module directory by default and lint everything.
        if options[:targets].nil? or options[:targets].empty?
          targets << PDK::Util.moduledir
        else
          targets.concat(options[:targets])
        end
        targets
      end

      def self.parse_format(options = {})
        format = ""

        if options[:format].nil? or options[:format].empty?
          format = ""
        elsif options[:format] == "junit"
          format = "--json"
        end

        format
      end

      def self.invoke(options = {})
        targets = parse_targets(options)
        format = parse_format(options)

        PDK.logger.info(_("Running %{cmd} on targets:\n  -%{targets}") % {cmd: cmd, targets: targets.join("\n  -")})
        opts = targets
        opts << format
        result = PDK::CLI::Exec.execute(cmd, *opts)
      end
    end
  end
end
