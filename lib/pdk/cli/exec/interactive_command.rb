require 'pdk'

module PDK
  module CLI
    module Exec
      class InteractiveCommand < Command
        def initialize(*argv)
          @argv = argv

          # Default to running things in the system context.
          @context = :system

          # Extra environment vars to add to base set.
          @environment = {}
        end

        def register_spinner(_spinner, _opts = {})
          raise 'This method is not implemented for PDK::CLI::Exec::InteractiveCommand'
        end

        def add_spinner(_message, _opts = {})
          raise 'This method is not implemented for PDK::CLI::Exec::InteractiveCommand'
        end

        def timeout
          raise 'This method is not implemented for PDK::CLI::Exec::InteractiveCommand'
        end

        def timeout=(_val)
          raise 'This method is not implemented for PDK::CLI::Exec::InteractiveCommand'
        end

        def exec_group=(_val)
          raise 'This method is not implemented for PDK::CLI::Exec::InteractiveCommand'
        end

        def execute!
          require 'pdk/util'

          @resolved_env = resolved_env_for_command

          if [:module, :pwd].include?(context)
            mod_root = PDK::Util.module_root

            unless mod_root
              raise PDK::CLI::FatalError, 'Current working directory is not part of a module. (No metadata.json was found.)'
            end

            unless context == :pwd || Dir.pwd == mod_root
              orig_workdir = Dir.pwd
              Dir.chdir(mod_root)
            end

            result = run_process_in_clean_env!
          else
            result = run_process!
          end

          {
            interactive: true,
            stdout: nil,
            stderr: nil,
            exit_code: result[:exit_code],
            duration: result[:duration],
          }
        ensure
          Dir.chdir(orig_workdir) if orig_workdir
        end

        protected

        # TODO: debug logging
        def run_process!
          command_string = argv.join(' ')
          PDK.logger.debug("Executing '%{command}' interactively" % { command: command_string })

          if context == :module
            PDK.logger.debug('Command environment:')
            @resolved_env.each do |var, val|
              PDK.logger.debug("  #{var}: #{val}")
            end
          end

          start_time = Time.now

          system(@resolved_env, *argv)

          exit_code = child_status.exitstatus
          duration = Time.now - start_time

          PDK.logger.debug("Execution of '%{command}' complete (duration: \
                              %{duration_in_seconds}s; exit code: %{exit_code})" %
                              {
                                command: command_string,
                                exit_code: exit_code,
                                duration_in_seconds: duration,
                              })

          { exit_code: exit_code, duration: duration }
        end

        def child_status
          require 'English'

          $CHILD_STATUS
        end

        def stop_spinner
          raise 'This method is not implemented for PDK::CLI::Exec::InteractiveCommand'
        end
      end
    end
  end
end
