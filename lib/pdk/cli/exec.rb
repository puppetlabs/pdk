require 'childprocess'
require 'tempfile'

module PDK
  module CLI
    module Exec
      # TODO: decide how to handle multiple output targets when underlying tool doesn't support that
      # TODO: decide what this method should return
      # TODO: decide how/when to connect stdin to child process for things like pry
      def self.execute(*cmd)
        process = ChildProcess.build(*cmd)

        process.io.stdout = Tempfile.new('stdout')
        process.io.stderr = Tempfile.new('stderr')

        begin
          # Make this process leader of a new group
          process.leader = true

          # start the process
          process.start

          # wait indefinitely for process to exit...
          process.wait

          stdout = process.io.stdout.open.read
          stderr = process.io.stderr.open.read
        ensure
          process.stop unless process.exited?
          process.io.stdout.close
          process.io.stderr.close
        end

        {
          exit_code: process.exit_code,
          stdout: stdout,
          stderr: stderr,
        }
      rescue ChildProcess::LaunchError => e
        raise PDK::CLI::FatalError, _("Failed to execute '%{command}': %{message}") % { command: cmd.join(' '), message: e.message }
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
    end
  end
end
