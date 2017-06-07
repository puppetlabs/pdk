require 'tmpdir'
require 'tempfile'

module PDK
  module Util
    # Generate a name for a temporary directory.
    #
    # @param base [String] A string to base the name generation off.
    #
    # @return [String] The temporary directory path.
    def make_tmpdir_name(base)
      Dir::Tmpname.make_tmpname(File.join(Dir.tmpdir, base), nil)
    end
    module_function :make_tmpdir_name

    # Returns the fully qualified path to a per-user PDK cachedir.
    #
    # @return [String] Fully qualified path to per-user PDK cachedir.
    def cachedir
      if Gem.win_platform?
        basedir = ENV['APPDATA']
      else
        basedir = Dir.home
      end

      return File.join(basedir, '.pdk', 'cache')
    end
    module_function :cachedir
  end
end
