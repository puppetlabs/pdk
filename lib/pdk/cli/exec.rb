require 'bundler'
require 'childprocess'
require 'tempfile'
require 'tty-spinner'

module PDK
  module CLI
    module Exec
      def self.execute(*cmd)
        Command.new(*cmd).execute!
      end

      def self.pdk_basedir
        @pdk_basedir ||= Gem.win_platform? ? 'C:/Program Files/Puppet Labs/DevelopmentKit' : '/opt/puppetlabs/sdk'
      end

      def self.git_bindir
        @git_dir ||= File.join(pdk_basedir, 'private', 'git', Gem.win_platform? ? 'cmd' : 'bin')
      end

      def self.git(*args)
        git_bin = Gem.win_platform? ? 'git.exe' : 'git'
        vendored_bin_path = File.join(git_bindir, git_bin)

        execute(try_vendored_bin(vendored_bin_path, git_bin), *args)
      end

      def self.bundle(*args)
        bundle_bin = Gem.win_platform? ? 'bundle.bat' : 'bundle'
        vendored_bin_path = File.join(pdk_basedir, 'private', 'ruby', '2.1.9', 'bin', bundle_bin)

        execute(try_vendored_bin(vendored_bin_path, bundle_bin), *args)
      end

      def self.try_vendored_bin(vendored_bin_path, fallback)
        if File.exist?(vendored_bin_path)
          PDK.logger.debug(_("Using '%{vendored_bin_path}'") % { fallback: fallback, vendored_bin_path: vendored_bin_path })
          vendored_bin_path
        else
          PDK.logger.debug(_("Trying '%{fallback}' from the system PATH, instead of '%{vendored_bin_path}'") % { fallback: fallback, vendored_bin_path: vendored_bin_path })
          fallback
        end
      end

      # TODO: decide how/when to connect stdin to child process for things like pry
      # TODO: need a way to set callbacks on new stdout/stderr data
      class Command
        attr_reader :argv
        attr_reader :context
        attr_accessor :timeout

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

          @spinner = TTY::Spinner.new(message, opts)
        end

        def execute!
          # Start spinning if configured.
          @spinner.auto_spin if @spinner

          if context == :module
            # FIXME: manage ENV more precisely as well.

            Dir.chdir(PDK::Util.module_root) do
              ::Bundler.with_clean_env do
                run_process!
              end
            end
          else
            run_process!
          end

          # Stop spinning when done (if configured).
          if @spinner
            if @process.exit_code.zero? && @success_message
              @spinner.success(@success_message)
            elsif @failure_message
              @spinner.error(@failure_message)
            else
              @spinner.stop
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
          begin
            @process.start
          rescue ChildProcess::LaunchError => e
            raise PDK::CLI::FatalError, _("Failed to execute '%{command}': %{message}") % { command: @process.argv.join(' '), message: e.message }
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
    end
  end
end
