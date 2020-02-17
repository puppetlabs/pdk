require 'pdk'

module PDK
  module Validate
    # An abstract validator that runs external commands within a Ruby Bundled environment
    # e.g. `puppet-lint`, or `puppet validate`
    #
    # At a a minimum child classes should implment the `name`, `cmd`, `pattern` and `parse_output` methods
    #
    # An example concrete implementation could look like:
    #
    # module PDK
    #   module Validate
    #     module Ruby
    #       class RubyRubocopValidator < ExternalCommandValidator
    #         def name
    #           'rubocop'
    #         end
    #
    #         def cmd
    #           'rubocop'
    #         end
    #
    #         def pattern
    #           '**/**.rb'
    #         end
    #
    #         def parse_options(targets)
    #           ['--format', 'json']
    #         end
    #
    #         def parse_output(report, result, _targets)
    #    ... ruby code ...
    #           report.add_event(
    #             line:     offense['location']['line'],
    #             column:   offense['location']['column'],
    #             message:  offense['message'],
    #             severity: offense['corrected'] ? 'corrected' : offense['severity'],
    #             test:     offense['cop_name'],
    #             state:    :failure,
    #           )
    #         end
    #       end
    #     end
    #   end
    # end
    #
    # @see PDK::Validate::InvokableValidator
    class ExternalCommandValidator < InvokableValidator
      # @return Array[PDK::CLI::Exec::Command] This is a private implementation attribute used for unit testing
      # @api private
      attr_reader :commands

      # @see PDK::Validate::Validator.spinner
      def spinner
        # The validator has sub-commands with their own spinners.
        nil
      end

      # Calculates the text of the spinner based on the target list
      # @return [String]
      # @abstract
      def spinner_text_for_targets(targets); end

      # The name of the command to be run for validation
      # @return [String]
      # @abstract
      def cmd; end

      # The full path to the command (cmd)
      # Can be overridden in child classes to a non-default path
      # @return [String]
      # @api private
      def cmd_path
        File.join(PDK::Util.module_root, 'bin', cmd)
      end

      # An array of command line arguments to pass to the command for validation
      # @return Array[String]
      # @abstract
      def parse_options(_targets)
        []
      end

      # Parses the output from the command and appends formatted events to the report.
      # This is called for each command, which is a group of targets
      #
      # @param report [PDK::Report] The report to add events to
      # @param result [Hash[Symbol => Object]] The result of validation command process
      # @param targets [Array[String]] The targets for this command result
      # @api private
      # @see PDK::CLI::Exec::Command.execute!
      # @abstract
      def parse_output(_report, _result, _targets); end

      # Prepares for invokation by parsing targets and creating the needed commands.
      # @api private
      # @see PDK::Validate::Validator.prepare_invoke!
      def prepare_invoke!
        return if @prepared
        super

        @targets, @skipped, @invalid = parse_targets
        @targets = [] if @targets.nil?

        target_groups = if @targets.empty? && allow_empty_targets?
                          # If we have no targets and we allow empty targets, create an empty target group list
                          [[]]
                        elsif invoke_style == :per_target
                          # If invoking :per_target, split the targets array into an array of
                          # single element arrays (one per target).
                          @targets.combination(1).to_a.compact
                        else
                          # Else we're invoking :once, wrap the targets array in another array. This is so we
                          # can loop through the invokes with the same logic, regardless of which invoke style
                          # is needed.
                          @targets.each_slice(1000).to_a.compact
                        end

        # Register all of the commands for all of the targets
        @commands = []
        target_groups.each do |invokation_targets|
          next if invokation_targets.empty? && !allow_empty_targets?
          cmd_argv = parse_options(invokation_targets).unshift(cmd_path).compact
          cmd_argv.unshift(File.join(PDK::Util::RubyVersion.bin_path, 'ruby.exe'), '-W0') if Gem.win_platform?

          command = PDK::CLI::Exec::Command.new(*cmd_argv).tap do |c|
            c.context = :module
            c.environment = { 'PUPPET_GEM_VERSION' => options[:puppet] } if options[:puppet]

            if spinners_enabled?
              parent_validator = options[:parent_validator]
              if parent_validator.nil? || parent_validator.spinner.nil? || !parent_validator.spinner.is_a?(TTY::Spinner::Multi)
                c.add_spinner(spinner_text_for_targets(invokation_targets))
              else
                spinner = TTY::Spinner.new("[:spinner] #{spinner_text_for_targets(invokation_targets)}", PDK::CLI::Util.spinner_opts_for_platform)
                parent_validator.spinner.register(spinner)
                c.register_spinner(spinner, PDK::CLI::Util.spinner_opts_for_platform)
              end
            end
          end

          @commands << { command: command, invokation_targets: invokation_targets }
        end
        nil
      end

      # Invokes the prepared commands as an ExecGroup
      # @see PDK::Validate::Validator.invoke
      def invoke(report)
        prepare_invoke!

        process_skipped(report, @skipped)
        process_invalid(report, @invalid)

        # Nothing to execute so return success
        return 0 if @commands.empty?

        PDK::Util::Bundler.ensure_binstubs!(cmd)

        exec_group = PDK::CLI::ExecGroup.create(name, { parallel: false }, options)

        # Register all of the commands for all of the targets
        @commands.each do |item|
          command = item[:command]
          invokation_targets = item[:invokation_targets]

          exec_group.register do
            result = command.execute!
            begin
              parse_output(report, result, invokation_targets.compact)
            rescue PDK::Validate::ParseOutputError => e
              $stderr.puts e.message
            end
            result[:exit_code]
          end
        end

        # Now execute and get the return code
        exec_group.exit_code
      end
    end
  end
end
