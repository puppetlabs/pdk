require 'pdk/util'

module PDK
  module Util
    class RubyVersion
      class << self
        extend Forwardable

        def_delegators :instance, :gem_path, :gem_home, :versions, :available_puppet_versions

        attr_writer :instance

        def instance
          @instance ||= new
        end
      end

      attr_reader :active_ruby_version

      def initialize
        @active_ruby_version = default_ruby_version
      end

      def gem_path
        if PDK::Util.package_install?
          # Subprocesses use their own set of gems which are managed by pdk or
          # installed with the package.
          File.join(PDK::Util.package_cachedir, 'ruby', versions[active_ruby_version])
        else
          # This allows the subprocess to find the 'bundler' gem, which isn't
          # in the cachedir above for gem installs.
          # TODO: There must be a better way to do this than shelling out to
          # gem...
          File.absolute_path(File.join(`gem which bundler`, '..', '..', '..', '..'))
        end
      end

      def gem_home
        # `bundle install --path` ignores all "system" installed gems and
        # causes unnecessary package installs. `bundle install` (without
        # --path) installs into GEM_HOME, which by default is non-user
        # writeable.
        # To still use the pre-installed packages, but allow folks to install
        # additional gems, we set GEM_HOME to the user's cachedir and put all
        # other cache locations onto GEM_PATH.
        # See https://stackoverflow.com/a/11277228 for background
        File.join(PDK::Util.cachedir, 'ruby', versions[active_ruby_version])
      end

      def versions
        @versions ||= if PDK::Util.package_install?
                        scan_for_packaged_rubies
                      else
                        { RbConfig::CONFIG['RUBY_PROGRAM_VERSION'] => RbConfig::CONFIG['ruby_version'] }
                      end
      end

      def available_puppet_versions
        return @available_puppet_versions unless @available_puppet_versions.nil?
        puppet_spec_files = Dir[File.join(gem_path, 'specifications', '**', 'puppet*.gemspec')]
        puppet_spec_files += Dir[File.join(gem_home, 'specifications', '**', 'puppet*.gemspec')]
        puppet_specs = puppet_spec_files.map { |r| Gem::Specification.load(r) }
        @available_puppet_versions = puppet_specs.select { |r| r.name == 'puppet' }.map { |r| r.version }.sort { |a, b| b <=> a }
      end

      private

      def scan_for_packaged_rubies
        { '2.4.3' => '2.4.0' }
      end

      def default_ruby_version
        versions.keys.sort { |a, b| Gem::Version.new(b) <=> Gem::Version.new(a) }.first
      end
    end
  end
end
