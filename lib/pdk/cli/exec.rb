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
          # start the process
          process.start

          # wait indefinitely for process to exit...
          process.wait

          stdout = process.io.stdout.open.read
          stderr = process.io.stderr.open.read
        ensure
          process.io.stdout.close
          process.io.stderr.close
        end

        {
          :exit_code => process.exit_code,
          :stdout => stdout,
          :stderr => stderr
        }
      end

      def self.pdk_basedir
        @pdk_basedir ||= Gem.win_platform? ? 'C:/Program Files/Puppet Labs/DevelopmentKit' : '/opt/puppetlabs/sdk'
      end

      def self.git_bindir
        @git_dir ||= File.join(pdk_basedir, 'private', 'git', 'bin')
      end

      def self.git(*args)
        git_path = ENV['PDK_USE_SYSTEM_BINARIES'].nil? ? File.join(git_bindir, 'git') : 'git'
        execute(git_path, *args)
      end
    end
  end
end
