require 'tmpdir'
require 'tempfile'

module PDK
  module Util
    # Searches upwards from current working directory for the given target file.
    #
    # @param target [String] Name of file to search for.
    #
    # @return [String, nil] Fully qualified path to the given target file if found,
    #   nil if the target file could not be found.
    def find_upwards(target)
      previous = nil
      current  = File.expand_path(Dir.pwd)

      until !File.directory?(current) || current == previous
        filename = File.join(current, target)
        return filename if File.file?(filename)
        current, previous = File.expand_path("..", current), current
      end
    end
    module_function :find_upwards

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

    # Returns path to the root of the module being worked on.
    #
    # @return [String, nil] Fully qualified base path to module, or nil if
    #   the current working dir does not appear to be within a module.
    def module_root
      if metadata_path = find_upwards("metdata.json")
        return File.dirname(metadata_path)
      else
        return nil
      end
    end
    module_function :module_root

  end
end
