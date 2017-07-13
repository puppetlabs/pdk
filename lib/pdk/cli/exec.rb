require 'bundler'
require 'childprocess'
require 'tempfile'
require 'tty-spinner'
require 'tty-which'

require 'pdk/util'

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

      def self.git_bindir
        @git_dir ||= File.join('private', 'git', Gem.win_platform? ? 'cmd' : 'bin')
      end

      def self.git_bin
        git_bin = Gem.win_platform? ? 'git.exe' : 'git'
        vendored_bin_path = File.join(git_bindir, git_bin)

        try_vendored_bin(vendored_bin_path, git_bin)
      end

      def self.git(*args)
        ensure_bin_present!(git_bin, 'git')

        execute(git_bin, *args)
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
          PDK.logger.debug(_("PDK package installation not found, trying '%{fallback}' from the system PATH instead") % { fallback: fallback })
          return fallback
        end

        if File.exist?(File.join(PDK::Util.pdk_package_basedir, vendored_bin_path))
          PDK.logger.debug(_("Using '%{vendored_bin_path}' from PDK package") % { vendored_bin_path: vendored_bin_path })
          File.join(PDK::Util.pdk_package_basedir, vendored_bin_path)
        else
          PDK.logger.debug(_("Could not find '%{vendored_bin_path}' in PDK package, trying '%{fallback}' from the system PATH instead") % { fallback: fallback, vendored_bin_path: vendored_bin_path })
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
        end

        def context=(new_context)
          unless [:system, :module].include?(new_context)
            raise ArgumentError, _("Expected execution context to be :system or :module but got '%{context}'") % { context: new_contenxt }
          end

          @context = new_context
        end

        def add_spinner(message, opts = {})
          @success_message = opts.delete(:success)
          @failure_message = opts.delete(:failure)

          @spinner = Gem.win_platform? ? WindowsSpinner.new(message, opts) : TTY::Spinner.new("[:spinner] #{message}", opts)
        end

        def execute!
          # Start spinning if configured.
          @spinner.auto_spin if @spinner

          # Add custom env vars.
          @environment.each do |k, v|
            @process.environment[k] = v
          end

          if context == :module
            # Subprocesses use their own set of gems which are managed by pdk or installed with the package.
            @process.environment['GEM_HOME'] = File.join(PDK::Util.cachedir, 'ruby', RbConfig::CONFIG['ruby_version'])

            if PDK::Util.gem_install?
              # This allows the subprocess to find the 'bundler' gem, which isn't in the cachedir above for gem installs.
              # bundler_gem_path = File.absolute_path(File.join(Gem.loaded_specs['bundler'].gem_dir, '..', '..', '..', '..', '..'))
              bundler_gem_path = File.absolute_path(File.join(`bundle show bundler`, '..', '..'))
              @process.environment['GEM_PATH'] = bundler_gem_path
            end

            # TODO: we should probably more carefully manage PATH and maybe other things too

            mod_root = PDK::Util.module_root

            unless mod_root
              @spinner.error

              raise PDK::CLI::FatalError, _('Current working directory is not part of a module. (No metadata.json was found.)')
            end

            Dir.chdir(mod_root) do
              ::Bundler.with_clean_env do
                run_process!
              end
            end
          else
            run_process!
          end

          # Stop spinning when done (if configured).
          if @spinner
            if @process.exit_code.zero?
              @spinner.success(@success_message || '')
            else
              @spinner.error(@failure_message || '')
            end
          end

          @stdout.rewind
          @stderr.rewind

          process_data = {
            stdout: @stdout.read,
            stderr: @stderr.read,
            exit_code: @process.exit_code,
          }

          return process_data
        ensure
          @stdout.close
          @stderr.close
        end

        protected

        def run_process!
          command_string = argv.join(' ')
          PDK.logger.debug(_("Executing '%{command}'") % { command: command_string })
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
        end
      end

      # This is a placeholder until we integrate ansicon into Windows packaging
      # or come up with some other progress indicator for Windows.
      class WindowsSpinner
        def initialize(message, _opts = {})
          @message = message
        end

        def auto_spin
          $stderr.print @message << '...'
        end

        def success(message = '')
          message ||= 'done.'

          $stderr.print message << "\n"
        end

        def error(message = '')
          message ||= 'FAILED'

          $stderr.print message << "\n"
        end
      end
    end
  end
end
