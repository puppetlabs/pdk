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

      def self.parse_options(_options, targets)
        targets
      end

      def self.invoke(options = {})
        targets = parse_targets(options)
        cmd_options = parse_options(options, targets)

        PDK.logger.debug(_('Running %{cmd} with options: %{options}') % { cmd: cmd, options: cmd_options })

        command = PDK::CLI::Exec::Command.new(cmd, *cmd_options).tap do |c|
          c.context = :module
          # c.add_spinner(_("Invoking %{c} %{args}") % { c: cmd, args: cmd_options.join(' ') })
        end

        result = command.execute!
        result
      end
    end
  end
end
