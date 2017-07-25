require 'pdk'
require 'pdk/cli/exec'

module PDK
  module Validate
    class BaseValidator
      # Controls how many times the validator is invoked.
      #
      #   :once -       The validator will be invoked once and passed all the
      #                 targets.
      #   :per_target - The validator will be invoked for each target
      #                 separately.
      INVOKE_STYLE = :once

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

      def self.spinner_text(_targets = nil)
        _('Invoking %{cmd}') % { cmd: cmd }
      end

      def self.invoke(report, options = {})
        targets = parse_targets(options)

        return 0 if targets.empty?

        PDK::Util::Bundler.ensure_binstubs!(cmd)

        # If invoking :per_target, split the targets array into an array of
        # single element arrays (one per target). If invoking :once, wrap the
        # targets array in another array. This is so we can loop through the
        # invokes with the same logic, regardless of which invoke style is
        # needed.
        targets = (self::INVOKE_STYLE == :per_target) ? targets.combination(1).to_a : Array[targets]
        exit_codes = []

        targets.each do |invokation_targets|
          cmd_argv = parse_options(options, invokation_targets).unshift(cmd_path)
          cmd_argv.unshift('ruby', '-W0') if Gem.win_platform?

          command = PDK::CLI::Exec::Command.new(*cmd_argv).tap do |c|
            c.context = :module
            c.add_spinner(spinner_text(invokation_targets))
          end

          result = command.execute!
          exit_codes << result[:exit_code]

          parse_output(report, result, invokation_targets)
        end

        exit_codes.max
      end
    end
  end
end
