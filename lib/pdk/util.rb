require 'tmpdir'
require 'tempfile'

module PDK
  module Util
    # Finds the parent directory path of the target file
    #
    # @param target [String] A string with the name of the target file
    #
    # @return [String] Fully qualified path to the parent directory of target
    def find_parent_dir(target)
      previous = nil
      current  = File.expand_path(Dir.pwd)

      until !File.directory?(current) || current == previous
        filename = File.join(current, target)
        return current if File.file?(filename)
        current, previous = File.expand_path("..", current), current
      end
    end
    module_function :find_parent_dir

    # Finds the file path of the target file
    #
    # @param target [String] A string with the name of the target file
    #
    # @return [String] Fully qualified path of the target file
    def find_upwards(target)
      parent = find_parent_dir(target)
      return File.join(parent, target) unless parent.nil?
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

    # Returns the fully qualified base path to a module being worked on.
    #
    # @return [String] Fully qualified base path to module.
    def moduledir
      return find_parent_dir("metadata.json")
    end
    module_function :moduledir

  end
end
