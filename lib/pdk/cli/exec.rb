require 'childprocess'

module PDK
  module CLI
    module Exec
      # TODO: decide how to handle multiple output targets when underlying tool doesn't support that
      # TODO: decide what this method should return
      # TODO: decide how/when to connect stdin to child process for things like pry
      def self.execute(cmd, options = {})
        process = ChildProcess.build(cmd)

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

        Struct.new("CommandResult", :exit_code, :stdout, :stderr)
        Struct::CommandResult.new(
          process.exit_code,
          stdout,
          stderr
        )
      end
    end
  end
end
