require 'pdk'

module PDK
  module Context
    # Represents a context for a directory based Control Repository
    class ControlRepo < PDK::Context::AbstractContext
      # @param repo_root [String] The root path for the control repo.
      # @param context_path [String] The path where this context was created from e.g. Dir.pwd
      # @see PDK::Context::AbstractContext
      def initialize(repo_root, context_path)
        super(context_path)
        @root_path = repo_root
        @environment_conf = nil
      end

      # @see PDK::Context::AbstractContext.pdk_compatible?
      def pdk_compatible?
        # Currently there is nothing to determine compatibility with the PDK for a
        # Control Repo. For now assume everything is compatible
        true
      end

      # The modulepath setting for this control repository as an array of strings. These paths are relative
      # and may contain interpolation strings (e.g. $basemodulepath)
      # @see https://puppet.com/docs/puppet/latest/config_file_environment.html#allowed-settings
      # @return [Array[String]] The modulepath setting for this control repository
      def module_paths
        return @module_paths unless @module_paths.nil?
        value = environment_conf['modulepath'] || ''
        # We have to use a hardcoded value here because File::PATH_SEPARATOR is ';' on Windows.
        # As the environment.conf is only used on Puppet Server, it's always ':'
        # Based on - https://github.com/puppetlabs/puppet/blob/f3e6d7e6d87f46408943a8e2176afb82ff6ea096/lib/puppet/settings/environment_conf.rb#L98-L106
        @module_paths = value.split(':')
      end

      # The relative module_paths that exist on disk.
      # @see https://puppet.com/docs/puppet/latest/config_file_environment.html#allowed-settings
      # @return [Array[String]] The relative module paths on disk
      def actualized_module_paths
        @actualized_module_paths ||= module_paths.reject { |path| path.start_with?('$') }
                                                 .select { |path| PDK::Util::Filesystem.directory?(PDK::Util::Filesystem.expand_path(File.join(root_path, path))) }
      end

      #:nocov:
      # @see PDK::Context::AbstractContext.display_name
      def display_name
        'a Control Repository context'
      end
      #:nocov:

      private

      # Memoization helper to read the environment.conf file.
      # @return [PDK::Config::IniFile]
      def environment_conf
        @environment_conf ||= PDK::ControlRepo.environment_conf_as_config(File.join(root_path, 'environment.conf'))
      end
    end
  end
end
