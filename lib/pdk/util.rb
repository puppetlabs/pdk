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

    def package_cachedir
      File.join(pdk_package_basedir, 'share', 'cache')
    end
    module_function :package_cachedir

    # Returns the fully qualified path to a per-user PDK cachedir.
    #
    # @return [String] Fully qualified path to per-user PDK cachedir.
    def cachedir
      if Gem.win_platform?
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

    # Iterate through possible JSON documents until we find one that is valid.
    #
    # @param [String] text the text in which to find a JSON document
    # @return [Hash, nil] subset of text as Hash of first valid JSON found, or nil if no valid
    #   JSON found in the text
    def find_first_json_in(text)
      find_valid_json_in(text)
    end
    module_function :find_first_json_in

    # Iterate through possible JSON documents for all valid JSON
    #
    # @param [String] text the text in which to find JSON document(s)
    # @return [Array<Hash>] subset of text as Array of all JSON object found, empty Array if none are found
    #   JSON found in the text
    def find_all_json_in(text)
      find_valid_json_in(text, break_on_first: false)
    end
    module_function :find_all_json_in

    # Iterate through possible JSON documents until we find one that is valid.
    #
    # @param [String] text the text in which to find a JSON document
    # @param [Hash] opts options
    # @option opts [Boolean] :break_on_first Whether or not to break after valid JSON is found, defaults to true
    #
    # @return [Hash, Array<Hash>, nil] subset of text as Hash of first valid JSON found, array of all valid JSON found, or nil if no valid
    #   JSON found in the text
    #
    # @private
    def find_valid_json_in(text, opts = {})
      break_on_first = opts.key?(:break_on_first) ? opts[:break_on_first] : true

      json_result = break_on_first ? nil : []

      text.scan(%r{\{(?:[^{}]|(?:\g<0>))*\}}x) do |str|
        begin
          if break_on_first
            json_result = JSON.parse(str)
            break
          else
            json_result.push(JSON.parse(str))
          end
        rescue JSON::ParserError
          next
        end
      end

      json_result
    end
    module_function :find_valid_json_in
  end
end
