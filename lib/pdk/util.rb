require 'pdk'

# PDK::Util::Windows can not be lazy loaded because it conditionally requires
# other files on Windows only. This can probably be fixed up with a later
# refactoring.
require 'pdk/util/windows'

autoload :Pathname, 'pathname'

module PDK
  module Util
    autoload :Bundler, 'pdk/util/bundler'
    autoload :ChangelogGenerator, 'pdk/util/changelog_generator'
    autoload :Env, 'pdk/util/env'
    autoload :Filesystem, 'pdk/util/filesystem'
    autoload :Git, 'pdk/util/git'
    autoload :JSONFinder, 'pdk/util/json_finder'
    autoload :PuppetStrings, 'pdk/util/puppet_strings'
    autoload :PuppetVersion, 'pdk/util/puppet_version'
    autoload :RubyVersion, 'pdk/util/ruby_version'
    autoload :TemplateURI, 'pdk/util/template_uri'
    autoload :VendoredFile, 'pdk/util/vendored_file'
    autoload :Version, 'pdk/util/version'

    MODULE_FOLDERS = %w[
      manifests
      lib/puppet
      lib/puppet_x
      lib/facter
      tasks
      facts.d
      functions
      types
    ].freeze

    #:nocov:
    # This method just wraps core Ruby functionality and
    # can be ignored for code coverage

    # Calls Kernel.exit with an exitcode
    def exit_process(exit_code)
      exit exit_code
    end
    #:nocov:

    # Searches upwards from current working directory for the given target file.
    #
    # @param target [String] Name of file to search for.
    # @param start_dir [String] Directory to start searching from, defaults to Dir.pwd
    #
    # @return [String, nil] Fully qualified path to the given target file if found,
    #   nil if the target file could not be found.
    def find_upwards(target, start_dir = nil)
      previous = nil
      current  = PDK::Util::Filesystem.expand_path(start_dir || Dir.pwd)

      until !PDK::Util::Filesystem.directory?(current) || current == previous
        filename = File.join(current, target)
        return filename if PDK::Util::Filesystem.file?(filename)
        previous = current
        current = PDK::Util::Filesystem.expand_path('..', current)
      end
    end
    module_function :find_upwards

    # Generate a name for a temporary directory.
    #
    # @param base [String] A string to base the name generation off.
    #
    # @return [String] The temporary directory path.
    def make_tmpdir_name(base)
      require 'tmpdir'

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
        unless PDK::Util::Filesystem.exist?(path)
          raise PDK::CLI::FatalError, "Cannot resolve a full path to '%{path}', as it does not currently exist." % { path: path }
        end
        PDK::Util::Windows::File.get_long_pathname(path)
      else
        PDK::Util::Filesystem.expand_path(path)
      end
    end
    module_function :canonical_path

    def package_install?
      require 'pdk/util/version'

      !PDK::Util::Version.version_file.nil?
    end
    module_function :package_install?

    def development_mode?
      require 'pdk/util/version'

      (!PDK::Util::Version.git_ref.nil? || PDK::VERSION.end_with?('.pre'))
    end
    module_function :development_mode?

    def gem_install?
      !(package_install? || development_mode?)
    end
    module_function :gem_install?

    def pdk_package_basedir
      raise PDK::CLI::FatalError, 'Package basedir requested for non-package install.' unless package_install?
      require 'pdk/util/version'

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
        File.join(PDK::Util::Env['LOCALAPPDATA'], 'PDK', 'cache')
      else
        File.join(Dir.home, '.pdk', 'cache')
      end
    end
    module_function :cachedir

    def configdir
      if Gem.win_platform?
        File.join(PDK::Util::Env['LOCALAPPDATA'], 'PDK')
      else
        File.join(PDK::Util::Env.fetch('XDG_CONFIG_HOME', File.join(Dir.home, '.config')), 'pdk')
      end
    end
    module_function :configdir

    def system_configdir
      return @system_configdir unless @system_configdir.nil?
      return @system_configdir = File.join(File::SEPARATOR, 'opt', 'puppetlabs', 'pdk', 'config') unless Gem.win_platform?

      return @system_configdir = File.join(PDK::Util::Env['ProgramData'], 'PuppetLabs', 'PDK') unless PDK::Util::Env['ProgramData'].nil?
      @system_configdir = File.join(PDK::Util::Env['AllUsersProfile'], 'PuppetLabs', 'PDK')
    end
    module_function :system_configdir

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
    # are found in the specified directory. If a directory is not specified, the current
    # working directory is used.
    #
    # @return [boolean] True if any folders from MODULE_FOLDERS are found in the current dir,
    #   false otherwise.
    def in_module_root?(path = Dir.pwd)
      PDK::Util::MODULE_FOLDERS.any? { |dir| PDK::Util::Filesystem.directory?(File.join(path, dir)) } ||
        PDK::Util::Filesystem.file?(File.join(path, 'metadata.json'))
    end
    module_function :in_module_root?

    # Iterate through possible JSON documents until we find one that is valid.
    #
    # @param [String] text the text in which to find a JSON document
    # @return [Hash, nil] subset of text as Hash of first valid JSON found, or nil if no valid
    #   JSON found in the text
    def find_first_json_in(text)
      find_all_json_in(text).first
    end
    module_function :find_first_json_in

    # Iterate through possible JSON documents for all valid JSON
    #
    # @param [String] text the text in which to find JSON document(s)
    # @return [Array<Hash>] subset of text as Array of all JSON object found, empty Array if none are found
    #   JSON found in the text
    def find_all_json_in(text)
      PDK::Util::JSONFinder.new(text).objects
    end
    module_function :find_all_json_in

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
    # @param module_path [String] The path to the root of the module. Default is determine the module root automatically
    def module_metadata(module_path = nil)
      require 'pdk/module/metadata'
      module_path ||= module_root
      PDK::Module::Metadata.from_file(File.join(module_path, 'metadata.json')).data
    end
    module_function :module_metadata

    # TO-DO: Refactor replacement of lib/pdk/module/build.rb:module_pdk_compatible? to use this function instead
    # @param module_path [String] The path to the root of the module. Default is determine the module root automatically
    def module_pdk_compatible?(module_path = nil)
      ['pdk-version', 'template-url'].any? { |key| module_metadata(module_path).key?(key) }
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

    # Does a deep copy instead of a shallow copy of an object.
    #
    # @param object [Object] The object to duplicate
    #
    # @return [Object] duplicate of the original object
    #   the current working dir does not appear to be within a module.
    def deep_duplicate(object)
      if object.is_a?(Array)
        object.map { |item| deep_duplicate(item) }
      elsif object.is_a?(Hash)
        hash = object.dup
        hash.each_pair { |key, value| hash[key] = deep_duplicate(value) }
        hash
      else
        object
      end
    end
    module_function :deep_duplicate
  end
end
