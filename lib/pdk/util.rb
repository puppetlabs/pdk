require 'tmpdir'
require 'tempfile'

require 'pdk/util/version'
require 'pdk/util/windows'
require 'pdk/util/vendored_file'
require 'pdk/util/filesystem'
require 'pdk/util/template_uri'
require 'pdk/util/puppet_strings'

module PDK
  module Util
    MODULE_FOLDERS = %w[
      manifests
      lib
      tasks
      facts.d
      functions
      types
    ].freeze

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
      t = Time.now.strftime('%Y%m%d')
      name = "#{base}#{t}-#{Process.pid}-#{rand(0x100000000).to_s(36)}"
      File.join(Dir.tmpdir, name)
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
          raise PDK::CLI::FatalError, _("Cannot resolve a full path to '%{path}', as it does not currently exist.") % { path: path }
        end
        PDK::Util::Windows::File.get_long_pathname(path)
      else
        File.expand_path(path)
      end
    end
    module_function :canonical_path

    def package_install?
      !PDK::Util::Version.version_file.nil?
    end
    module_function :package_install?

    def development_mode?
      (!PDK::Util::Version.git_ref.nil? || PDK::VERSION.end_with?('.pre'))
    end
    module_function :development_mode?

    def gem_install?
      !(package_install? || development_mode?)
    end
    module_function :gem_install?

    def pdk_package_basedir
      raise PDK::CLI::FatalError, _('Package basedir requested for non-package install.') unless package_install?

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

    def configdir
      if Gem.win_platform?
        File.join(ENV['LOCALAPPDATA'], 'PDK')
      else
        File.join(ENV.fetch('XDG_CONFIG_HOME', File.join(Dir.home, '.config')), 'pdk')
      end
    end
    module_function :configdir

    # Returns path to the root of the module being worked on.
    #
    # @return [String, nil] Fully qualified base path to module, or nil if
    #   the current working dir does not appear to be within a module.
    def module_root
      metadata_path = find_upwards('metadata.json')
      if metadata_path
        File.dirname(metadata_path)
      elsif in_module_root?
        Dir.pwd
      else
        nil
      end
    end
    module_function :module_root

    # The module's fixtures directory for spec testing
    # @return [String] - the path to the module's fixtures directory
    def module_fixtures_dir
      dir = module_root
      File.join(module_root, 'spec', 'fixtures') unless dir.nil?
    end
    module_function :module_fixtures_dir

    # Returns true or false depending on if any of the common directories in a module
    # are found in the current directory
    #
    # @return [boolean] True if any folders from MODULE_FOLDERS are found in the current dir,
    #   false otherwise.
    def in_module_root?
      PDK::Util::MODULE_FOLDERS.any? { |dir| File.directory?(dir) }
    end
    module_function :in_module_root?

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

    # Returns the targets' paths relative to the working directory
    #
    # @return [Array<String>] The absolute or path to the target
    def targets_relative_to_pwd(targets)
      targets.map do |t|
        if Pathname.new(t).absolute?
          Pathname.new(t).relative_path_from(Pathname.pwd)
        else
          t
        end
      end
    end
    module_function :targets_relative_to_pwd

    # TO-DO: Refactor replacement of lib/pdk/module/build.rb:metadata to use this function instead
    def module_metadata
      PDK::Module::Metadata.from_file(File.join(module_root, 'metadata.json')).data
    end
    module_function :module_metadata

    # TO-DO: Refactor replacement of lib/pdk/module/build.rb:module_pdk_compatible? to use this function instead
    def module_pdk_compatible?
      ['pdk-version', 'template-url'].any? { |key| module_metadata.key?(key) }
    end
    module_function :module_pdk_compatible?

    def module_pdk_version
      metadata = module_metadata

      if metadata.nil? || metadata.fetch('pdk-version', nil).nil?
        nil
      else
        metadata['pdk-version'].split.first
      end
    rescue ArgumentError => e
      PDK.logger.error(e)
      nil
    end
    module_function :module_pdk_version
  end
end
