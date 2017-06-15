require 'tmpdir'
require 'tempfile'
require 'puppet/util/windows'

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
        previous = current
        current = File.expand_path('..', current)
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

    # Return an expanded, absolute path
    #
    # @param path [String] Existing path that may not be canonical
    #
    # @return [String] Canonical path
    def canonical_path(path)
      if Gem.win_platform?
        unless File.exist?(path)
          raise PDK::CLI::FatalError, _("Cannot resolve a full path to '%{path}' as it does not currently exist") % { path: path }
        end
        Puppet::Util::Windows::File.get_long_pathname(path)
      else
        File.expand_path(path)
      end
    end
    module_function :canonical_path

    # Returns the fully qualified path to a per-user PDK cachedir.
    #
    # @return [String] Fully qualified path to per-user PDK cachedir.
    def cachedir
      basedir = if Gem.win_platform?
                  ENV['LOCALAPPDATA']
                else
                  Dir.home
                end

      File.join(basedir, '.pdk', 'cache')
    end
    module_function :cachedir

    # Returns path to the root of the module being worked on.
    #
    # @return [String, nil] Fully qualified base path to module, or nil if
    #   the current working dir does not appear to be within a module.
    def module_root
      metadata_path = find_upwards('metadata.json')
      if metadata_path
        File.dirname(metadata_path)
      else
        nil
      end
    end
    module_function :module_root
  end
end
