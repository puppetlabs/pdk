require 'open3'

module Pick
  module CLI
    module Exec
      # TODO: standardize how we want to execute commands
      def self.execute(cmd, options = {})
        out = ''
        err = ''
        Open3.popen3(cmd) do |stdin, stdout, stderr|
          out = stdout.read.to_s
          err = stderr.read.to_s
        end
        "#{out}, #{err}"
      end
    end
  end
end
