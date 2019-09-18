require 'pdk'

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

      # Controls how the validator behaves if not passed any targets.
      #
      #   true  - PDK will not pass the globbed targets to the validator command
      #           and it will instead rely on the underlying tool to find its
      #           own default targets.
      #   false - PDK will pass the globbed targets to the validator command.
      ALLOW_EMPTY_TARGETS = false

      IGNORE_DOTFILES = true

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

        targets = options.fetch(:targets, []).empty? ? [PDK::Util.module_root] : options[:targets]

        targets.map! { |r| r.gsub(File::ALT_SEPARATOR, File::SEPARATOR) } if File::ALT_SEPARATOR
        skipped = []
        invalid = []
        matched = targets.map { |target|
          if respond_to?(:pattern)
            if PDK::Util::Filesystem.directory?(target)
              target_root = PDK::Util.module_root
              pattern_glob = Array(pattern).map { |p| PDK::Util::Filesystem.glob(File.join(target_root, p), File::FNM_DOTMATCH) }
              target_list = pattern_glob.flatten
                                        .select { |glob| PDK::Util::Filesystem.fnmatch(File.join(PDK::Util::Filesystem.expand_path(PDK::Util.canonical_path(target)), '*'), glob, File::FNM_DOTMATCH) }
                                        .map { |glob| Pathname.new(glob).relative_path_from(Pathname.new(PDK::Util.module_root)).to_s }

              ignore_list = ignore_pathspec
              target_list = target_list.reject { |file| ignore_list.match(file) }

              skipped << target if target_list.flatten.empty?
              target_list
            elsif PDK::Util::Filesystem.file?(target)
              if Array(pattern).include? target
                target
              elsif Array(pattern).any? { |p| PDK::Util::Filesystem.fnmatch(PDK::Util::Filesystem.expand_path(p), PDK::Util::Filesystem.expand_path(target), File::FNM_DOTMATCH) }
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

      def self.ignore_pathspec
        require 'pdk/module'

        ignore_pathspec = PDK::Module.default_ignored_pathspec(ignore_dotfiles?)

        if respond_to?(:pattern_ignore)
          Array(pattern_ignore).each do |pattern|
            ignore_pathspec.add(pattern)
          end
        end

        ignore_pathspec
      end

      def self.ignore_dotfiles?
        self::IGNORE_DOTFILES
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

      def self.allow_empty_targets?
        self::ALLOW_EMPTY_TARGETS == true
      end

      def self.invoke(report, options = {})
        require 'pdk/cli/exec/command'

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
        #
        if self::INVOKE_STYLE == :per_target
          targets = targets.combination(1).to_a
        else
          require 'pdk/cli/exec_group'
          targets = targets.each_slice(1000).to_a
          options[:split_exec] = PDK::CLI::ExecGroup.new(spinner_text(targets), parallel: false)
        end

        if options.fetch(:targets, []).empty? && allow_empty_targets?
          targets = [[]]
        end

        exit_codes = []

        targets.each do |invokation_targets|
          cmd_argv = parse_options(options, invokation_targets).unshift(cmd_path).compact
          cmd_argv.unshift(File.join(PDK::Util::RubyVersion.bin_path, 'ruby.exe'), '-W0') if Gem.win_platform?

          command = PDK::CLI::Exec::Command.new(*cmd_argv).tap do |c|
            c.context = :module
            c.environment = { 'PUPPET_GEM_VERSION' => options[:puppet] } if options[:puppet]
            unless options[:split_exec]
              exec_group = options[:exec_group]
              if exec_group
                sub_spinner = exec_group.add_spinner(spinner_text(invokation_targets))
                c.register_spinner(sub_spinner)
              else
                c.add_spinner(spinner_text(invokation_targets))
              end
            end
          end

          if options[:split_exec]
            options[:split_exec].register do
              result = command.execute!

              begin
                parse_output(report, result, invokation_targets.compact)
              rescue PDK::Validate::ParseOutputError => e
                $stderr.puts e.message
              end
              result[:exit_code]
            end
          else
            result = command.execute!
            exit_codes << result[:exit_code]

            begin
              parse_output(report, result, invokation_targets.compact)
            rescue PDK::Validate::ParseOutputError => e
              $stderr.puts e.message
            end
          end
        end

        options.key?(:split_exec) ? options[:split_exec].exit_code : exit_codes.max
      end
    end
  end
end
