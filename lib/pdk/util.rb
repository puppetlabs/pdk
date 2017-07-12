require 'tmpdir'
require 'tempfile'
require 'puppet/util/windows'

require 'pdk/util/version'

module PDK
  module Util
    # Searches upwards from current working directory for the given target file.
    #
    # @param target [String] Name of file to search for.
    # @param start_dir [String] Directory to start searching from, defaults to Dir.pwd
    #
    # @return [String, nil] Fully qualified path to the given target file if found,
    #   nil if the target file could not be found.
    def find_upwards(target, start_dir = nil)
      previous = nil
      current  = File.expand_path(start_dir || Dir.pwd)

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

    def package_install?
      !PDK::Util::Version.version_file.nil?
    end
    module_function :package_install?

    def gem_install?
      !package_install?
    end
    module_function :gem_install?

    def pdk_package_basedir
      raise PDK::CLI::FatalError, _('Package basedir requested for non-package install') unless package_install?

      File.dirname(PDK::Util::Version.version_file)
    end
    module_function :pdk_package_basedir

    # Returns the fully qualified path to a per-user PDK cachedir.
    #
    # @return [String] Fully qualified path to per-user PDK cachedir.
    def cachedir
      if package_install?
        File.join(pdk_package_basedir, 'share', 'cache')
      elsif Gem.win_platform?
        File.join(ENV['LOCALAPPDATA'], 'PDK', 'cache')
      else
        File.join(Dir.home, '.pdk', 'cache')
      end
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
