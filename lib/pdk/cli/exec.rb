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

      def self.bundle_bin
        bundle_bin = Gem.win_platform? ? 'bundle.bat' : 'bundle'
        vendored_bin_path = File.join(pdk_basedir, 'private', 'ruby', '2.1.9', 'bin', bundle_bin)

        try_vendored_bin(vendored_bin_path, bundle_bin)
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

          @spinner = TTY::Spinner.new("[:spinner] #{message}", opts)
        end

        def execute!
          # Start spinning if configured.
          @spinner.auto_spin if @spinner

          # Add custom env vars.
          @environment.each do |k, v|
            @process.environment[k] = v
          end

          if context == :module
            # TODO: we should probably more carefully manage PATH and maybe other things too
            @process.environment['GEM_HOME'] = File.join(PDK::Util.cachedir, 'bundler', 'ruby', RbConfig::CONFIG['ruby_version'])
            @process.environment['GEM_PATH'] = pdk_gem_path

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
          begin
            @process.start
          rescue ChildProcess::LaunchError => e
            msg = if @process.respond_to?(:argv)
                    _("Failed to execute '%{command}': %{message}") % { command: @process.argv.join(' '), message: e.message }
                  else
                    _('Failed to execute process: %{message}') % { message: e.message }
                  end
            raise PDK::CLI::FatalError, msg
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

        def pdk_gem_path
          @pdk_gem_path ||= find_pdk_gem_path
        end

        def find_pdk_gem_path
          # /opt/puppetlabs/sdk/private/ruby/2.1.9/lib/ruby/gems/2.1.0
          package_gem_path = File.join(PDK::CLI::Exec.pdk_basedir, 'private', 'ruby', RUBY_VERSION, 'lib', 'ruby', 'gems', RbConfig::CONFIG['ruby_version'])

          if File.directory?(package_gem_path)
            package_gem_path
          else
            # FIXME: calculate this more reliably
            File.absolute_path(File.join(`bundle show bundler`, '..', '..'))
          end
        end
      end
    end
  end
end
