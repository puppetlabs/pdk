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

      # Parses the target strings provided from the CLI
      #
      # @param options [Hash] A Hash containing the input options from the CLI.
      #
      # @return targets [Array] An Array of Strings containing target file paths
      #                         for the validator to validate.
      # @return skipped [Array] An Array of Strings containing targets
      #                         that are skipped due to target not containing
      #                         any files that can be validated by the validator.
      # @return invalid [Array] An Array of Strings containing targets that do
      #                         not exist, and will not be run by validator.
      def self.parse_targets(options)
        # If no targets are specified, then we will run validations from the
        # base module directory.
        targets = if options[:targets].nil? || options[:targets].empty?
                    [PDK::Util.module_root]
                  else
                    options[:targets]
                  end

        targets.map! { |r| r.gsub(File::ALT_SEPARATOR, File::SEPARATOR) } if File::ALT_SEPARATOR
        skipped = []
        invalid = []
        matched = targets.map { |target|
          if respond_to?(:pattern)
            if File.directory?(target)
              pattern_glob = Array(pattern).map { |p| Dir.glob(File.join(PDK::Util.module_root, p)) }
              target_list = pattern_glob.flatten.select { |file| File.fnmatch(File.join(File.expand_path(target), '*'), file) }
              skipped << target if target_list.flatten.empty?
              target_list
            elsif File.file?(target)
              if Array(pattern).include? target
                target
              elsif Array(pattern).any? { |p| File.fnmatch(File.expand_path(p), File.expand_path(target)) }
                target
              else
                skipped << target
                next
              end
            else
              invalid << target
              next
            end
          else
            target
          end
        }.compact.flatten
        [matched, skipped, invalid]
      end

      def self.parse_options(_options, targets)
        targets
      end

      def self.spinner_text(_targets = nil)
        _('Invoking %{cmd}') % { cmd: cmd }
      end

      def self.process_skipped(report, skipped = [])
        skipped.each do |skipped_target|
          PDK.logger.debug(_('%{validator}: Skipped \'%{target}\'. Target does not contain any files to validate (%{pattern}).') % { validator: name, target: skipped_target, pattern: pattern })
          report.add_event(
            file:     skipped_target,
            source:   name,
            message:  _('Target does not contain any files to validate (%{pattern}).') % { pattern: pattern },
            severity: :info,
            state:    :skipped,
          )
        end
      end

      def self.process_invalid(report, invalid = [])
        invalid.each do |invalid_target|
          PDK.logger.debug(_('%{validator}: Skipped \'%{target}\'. Target file not found.') % { validator: name, target: invalid_target })
          report.add_event(
            file:     invalid_target,
            source:   name,
            message:  _('File does not exist.'),
            severity: :error,
            state:    :error,
          )
        end
      end

      def self.invoke(report, options = {})
        targets, skipped, invalid = parse_targets(options)

        process_skipped(report, skipped)
        process_invalid(report, invalid)

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
            exec_group = options[:exec_group]
            if exec_group
              sub_spinner = exec_group.add_spinner(spinner_text(invokation_targets))
              c.register_spinner(sub_spinner)
            else
              c.add_spinner(spinner_text(invokation_targets))
            end
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
