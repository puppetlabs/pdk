require 'pdk'
require 'pdk/cli/exec'

module PDK
  module Validate
    class BaseValidator
      def self.parse_targets(options)
        # If no targets are specified, then we will run validations from the
        # base module directory.
        if options[:targets].nil? || options[:targets].empty?
          [PDK::Util.module_root]
        else
          options[:targets]
        end
      end

      def self.parse_options(options, targets)
        targets
      end

      def self.invoke(options = {})
        targets = parse_targets(options)
        cmd_options = parse_options(options, targets)

        PDK.logger.debug(_("Running %{cmd} with options: %{options}") % {cmd: cmd, options: cmd_options})
        result = PDK::CLI::Exec.execute(cmd, *cmd_options)
        result
      end
    end
  end
end
