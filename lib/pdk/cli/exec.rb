require 'bundler'
require 'childprocess'
require 'tempfile'
require 'tty-spinner'
require 'tty-which'

require 'pdk/util'
require 'pdk/util/git'
require 'pdk/util/ruby_version'

module PDK
  module CLI
    module Exec
      def self.execute(*cmd)
        Command.new(*cmd).execute!
      end

      def self.ensure_bin_present!(bin_path, bin_name)
        message = _('Unable to find `%{name}`. Check that it is installed and try again.') % {
          name: bin_name,
        }

        raise PDK::CLI::FatalError, message unless TTY::Which.exist?(bin_path)
      end

      def self.bundle(*args)
        ensure_bin_present!(bundle_bin, 'bundler')

        execute(bundle_bin, *args)
      end

      def self.bundle_bin
        bundle_bin = Gem.win_platform? ? 'bundle.bat' : 'bundle'
        vendored_bin_path = File.join('private', 'ruby', '2.1.9', 'bin', bundle_bin)

        try_vendored_bin(vendored_bin_path, bundle_bin)
      end

      def self.try_vendored_bin(vendored_bin_path, fallback)
        unless PDK::Util.package_install?
          PDK.logger.debug(_("PDK package installation not found. Trying '%{fallback}' from the system PATH instead.") % { fallback: fallback })
          return fallback
        end

        if File.exist?(File.join(PDK::Util.pdk_package_basedir, vendored_bin_path))
          PDK.logger.debug(_("Using '%{vendored_bin_path}' from PDK package.") % { vendored_bin_path: vendored_bin_path })
          File.join(PDK::Util.pdk_package_basedir, vendored_bin_path)
        else
          PDK.logger.debug(_("Could not find '%{vendored_bin_path}' in PDK package. Trying '%{fallback}' from the system PATH instead.") % { fallback: fallback, vendored_bin_path: vendored_bin_path })
          fallback
        end
      end

      # TODO: decide how/when to connect stdin to child process for things like pry
      # TODO: need a way to set callbacks on new stdout/stderr data
      class Command
        attr_reader :argv
        attr_reader :context
        attr_accessor :timeout
        attr_accessor :environment
        attr_writer :exec_group

        def initialize(*argv)
          @argv = argv

          @process = ChildProcess.build(*@argv)
          @process.leader = true

          @stdout = Tempfile.new('stdout').tap { |io| io.sync = true }
          @stderr = Tempfile.new('stderr').tap { |io| io.sync = true }

          @process.io.stdout = @stdout
          @process.io.stderr = @stderr

          # Default to running things in the system context.
          @context = :system

          # Extra environment vars to add to base set.
          @environment = {}

          # Register the ExecGroup when running in parallel
          @exec_group = nil
        end

        def context=(new_context)
          unless [:system, :module].include?(new_context)
            raise ArgumentError, _("Expected execution context to be :system or :module but got '%{context}'.") % { context: new_context }
          end

          @context = new_context
        end

        def register_spinner(spinner, opts = {})
          return unless PDK::CLI::Util.interactive?
          @success_message = opts.delete(:success)
          @failure_message = opts.delete(:failure)

          @spinner = spinner
        end

        def add_spinner(message, opts = {})
          return unless PDK::CLI::Util.interactive?
          @success_message = opts.delete(:success)
          @failure_message = opts.delete(:failure)

          @spinner = TTY::Spinner.new("[:spinner] #{message}", opts.merge(PDK::CLI::Util.spinner_opts_for_platform))
        end

        def execute!
          # Start spinning if configured.
          @spinner.auto_spin if @spinner

          # Add custom env vars.
          @environment.each do |k, v|
            @process.environment[k] = v
          end

          if context == :module
            @process.environment['GEM_HOME'] = PDK::Util::RubyVersion.gem_home
            @process.environment['GEM_PATH'] = PDK::Util::RubyVersion.gem_path

            # Make sure invocation of Ruby prefers our private installation.
            package_binpath = PDK::Util.package_install? ? File.join(PDK::Util.pdk_package_basedir, 'bin') : nil
            @process.environment['PATH'] = [
              RbConfig::CONFIG['bindir'],
              File.join(@process.environment['GEM_HOME'], 'bin'),
              File.join(@process.environment['GEM_PATH'], 'bin'),
              package_binpath,
              ENV['PATH'],
              PDK::Util.package_install? ? PDK::Util::Git.git_paths : nil,
            ].compact.flatten.join(File::PATH_SEPARATOR)

            mod_root = PDK::Util.module_root

            unless mod_root
              @spinner.error if @spinner

              raise PDK::CLI::FatalError, _('Current working directory is not part of a module. (No metadata.json was found.)')
            end

            if Dir.pwd == mod_root
              run_process_in_clean_env!
            else
              Dir.chdir(mod_root) do
                run_process_in_clean_env!
              end
            end
          else
            run_process!
          end

          # Stop spinning when done (if configured).
          stop_spinner

          @stdout.rewind
          @stderr.rewind

          process_data = {
            stdout: @stdout.read,
            stderr: @stderr.read,
            exit_code: @process.exit_code,
            duration: @duration,
          }

          return process_data
        ensure
          @stdout.close
          @stderr.close
        end

        protected

        def stop_spinner
          return unless @spinner

          # If it is a single spinner, we need to send it a success/error message
          if @process.exit_code.zero?
            @spinner.success(@success_message || '')
          else
            @spinner.error(@failure_message || '')
          end
        end

        def run_process_in_clean_env!
          ::Bundler.with_clean_env do
            run_process!
          end
        end

        def run_process!
          command_string = argv.join(' ')
          PDK.logger.debug(_("Executing '%{command}'") % { command: command_string })
          if context == :module
            PDK.logger.debug(_("Command environment: GEM_HOME is '%{gem_home}' and GEM_PATH is '%{gem_path}'") % { gem_home: @process.environment['GEM_HOME'],
                                                                                                                   gem_path: @process.environment['GEM_PATH'] })
          end
          start_time = Time.now
          begin
            @process.start
          rescue ChildProcess::LaunchError => e
            raise PDK::CLI::FatalError, _("Failed to execute '%{command}': %{message}") % { command: command_string, message: e.message }
          end

          if timeout
            begin
              @process.poll_for_exit(timeout)
            rescue ChildProcess::TimeoutError
              @process.stop # tries increasingly harsher methods to kill the process.
            end
          else
            # Wait indfinitely if no timeout set.
            @process.wait
          end
          @duration = Time.now - start_time
          PDK.logger.debug(_("Execution of '%{command}' complete (duration: %{duration_in_seconds}s; exit code: %{exit_code})") %
            { command: command_string, duration_in_seconds: @duration, exit_code: @process.exit_code })
        end
      end
    end
  end
end
