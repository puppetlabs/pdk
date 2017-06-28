require 'pdk'
require 'pdk/cli/exec'

module PDK
  module Validate
    class BaseValidator
      def self.cmd_path
        File.join(PDK::Util.module_root, 'bin', cmd)
      end

      def self.parse_targets(options)
        # If no targets are specified, then we will run validations from the
        # base module directory.
        targets = if options[:targets].nil? || options[:targets].empty?
                    [PDK::Util.module_root]
                  else
                    options[:targets]
                  end

        targets.map { |target|
          if respond_to?(:pattern)
            if File.directory?(target)
              Array[pattern].flatten.map { |p| Dir.glob(File.join(target, p)) }
            else
              target
            end
          else
            target
          end
        }.flatten
      end

      def self.parse_options(_options, targets)
        targets
      end

      def self.spinner_text
        _('Invoking %{cmd}') % { cmd: cmd }
      end

      def self.invoke(report, options = {})
        targets = parse_targets(options)

        return 0 if targets.empty?

        PDK::Util::Bundler.ensure_binstubs!(cmd)
        cmd_argv = parse_options(options, targets).unshift(cmd_path)
        cmd_argv.unshift('ruby', '-W0') if Gem.win_platform?

        PDK.logger.debug(_('Running %{cmd}') % { cmd: cmd_argv.join(' ') })

        command = PDK::CLI::Exec::Command.new(*cmd_argv).tap do |c|
          c.context = :module
          c.add_spinner(spinner_text)
        end

        result = command.execute!

        parse_output(report, result, targets)

        result[:exit_code]
      end
    end
  end
end
