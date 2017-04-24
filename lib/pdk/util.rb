require 'tmpdir'
require 'tempfile'

module PDK
  module Util
    def which(cmd)
      if ENV['PDK_USE_SYSTEM_BINARIES']
        cmd
      else
        path = Gem.win_platform? ? "" : "/opt/puppetlabs/sdk/bin"
        File.join(path, cmd)
      end
    end
    module_function :which

    # Generate a name for a temporary directory.
    #
    # @param base [String] A string to base the name generation off.
    #
    # @return [String] The temporary directory path.
    def make_tmpdir_name(base)
      Dir::Tmpname.make_tmpname(File.join(Dir.tmpdir, base), nil)
    end
    module_function :make_tmpdir_name
  end
end
