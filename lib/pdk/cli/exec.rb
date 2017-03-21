require 'childprocess'

module PDK
  module CLI
    module Exec
      # TODO: decide how to handle multiple output targets when underlying tool doesn't support that
      # TODO: decide what this method should return
      # TODO: decide how/when to connect stdin to child process for things like pry
      def self.execute(cmd, options = {})
        process = ChildProcess.build(cmd)

        # inherit stdout/stderr from parent...
        process.io.inherit!

        # start the process
        process.start

        # wait indefinitely for process to exit...
        process.wait

        # get the exit code
        process.exit_code #=> 0
      end
    end
  end
end
