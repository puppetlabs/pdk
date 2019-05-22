require 'pdk/util'
require 'pdk/util/git'

module PDK
  module Util
    class PuppetVersion
      class << self
        extend Forwardable

        def_delegators :instance, :puppet_dev_env, :puppet_dev_path, :fetch_puppet_dev, :find_gem_for, :from_pe_version, :from_module_metadata, :latest_available

        attr_writer :instance

        def instance
          @instance ||= new
        end
      end

      PE_VERSIONS_URL = 'https://forgeapi.puppet.com/private/versions/pe'.freeze
      DEFAULT_PUPPET_DEV_URL = 'https://github.com/puppetlabs/puppet'.freeze
      DEFAULT_PUPPET_DEV_BRANCH = 'master'.freeze

      def puppet_dev_env
        {
          gem_version: 'file://%{path}' % { path: puppet_dev_path },
          ruby_version: PDK::Util::RubyVersion.latest_ruby_version,
        }
      end

      def puppet_dev_path
        File.join(PDK::Util.cachedir, 'src', 'puppet')
      end

      def latest_available
        latest = find_gem(Gem::Requirement.create('>= 0'))

        if latest.nil?
          raise ArgumentError, _('Unable to find a Puppet gem in current Ruby environment or from Rubygems.org.')
        end

        latest
      end

      def fetch_puppet_dev
        # Check if the source is cloned and is a readable git repo
        unless PDK::Util::Git.remote_repo? puppet_dev_path
          # Check if the path has something in it already. Delete it and prepare for clone if so.
          if File.exist? puppet_dev_path
            File.delete(puppet_dev_path) if File.file? puppet_dev_path
            FileUtils.rm_rf(puppet_dev_path) if File.directory? puppet_dev_path
          end

          FileUtils.mkdir_p puppet_dev_path
          clone_result = PDK::Util::Git.git('clone', DEFAULT_PUPPET_DEV_URL, puppet_dev_path)
          return if clone_result[:exit_code].zero?

          PDK.logger.error clone_result[:stdout]
          PDK.logger.error clone_result[:stderr]
          raise PDK::CLI::FatalError, _("Unable to clone git repository at '%{repo}'.") % { repo: DEFAULT_PUPPET_DEV_URL }
        end

        # Fetch Updates from remote repository
        fetch_result = PDK::Util::Git.git('-C', puppet_dev_path, 'fetch', 'origin')

        unless fetch_result[:exit_code].zero?
          PDK.logger.error fetch_result[:stdout]
          PDK.logger.error fetch_result[:stderr]
          raise PDK::CLI::FatalError, _("Unable to fetch from git remote at '%{repo}'.") % { repo: DEFAULT_PUPPET_DEV_URL }
        end

        # Reset local repo to latest
        reset_result = PDK::Util::Git.git('-C', puppet_dev_path, 'reset', '--hard', 'origin/master')
        return if reset_result[:exit_code].zero?

        PDK.logger.error reset_result[:stdout]
        PDK.logger.error reset_result[:stderr]
        raise PDK::CLI::FatalError, _("Unable to update git repository at '%{cachedir}'.") % { repo: puppet_dev_path }
      end

      def find_gem_for(version_str)
        version = parse_specified_version(version_str)

        # Look for a gem matching exactly the version passed in.
        if version.segments.length == 3
          exact_match_gem = find_gem(Gem::Requirement.create(version))
          return exact_match_gem unless exact_match_gem.nil?
        end

        # Construct a pessimistic version constraint to find the latest
        # available gem matching the level of specificity of version_str.
        requirement_string = version.approximate_recommendation
        requirement_string += '.0' unless version.segments.length == 1
        latest_requirement = Gem::Requirement.create(requirement_string)

        latest_available_gem = find_gem(latest_requirement)

        if latest_available_gem.nil?
          raise ArgumentError, _('Unable to find a Puppet gem matching %{requirement}.') % {
            requirement: latest_requirement,
          }
        end

        # Only issue this warning if they requested an exact version that isn't available.
        if version.segments.length == 3
          PDK.logger.warn(_('Puppet %{requested_version} is not available, activating %{found_version} instead.') % {
            requested_version: version_str,
            found_version:     latest_available_gem[:gem_version].version,
          })
        end

        latest_available_gem
      end

      def from_pe_version(version_str)
        version = parse_specified_version(version_str)

        gem_version = pe_version_map.find do |version_map|
          version_map[:requirement].satisfied_by?(version)
        end

        if gem_version.nil?
          raise ArgumentError, _('Unable to map Puppet Enterprise version %{pe_version} to a Puppet version.') % {
            pe_version: version_str,
          }
        end

        PDK.logger.info _('Puppet Enterprise %{pe_version} maps to Puppet %{puppet_version}.') % {
          pe_version:     version_str,
          puppet_version: gem_version[:gem_version],
        }

        find_gem_for(gem_version[:gem_version])
      end

      def from_module_metadata(metadata = nil)
        if metadata.nil?
          metadata_file = PDK::Util.find_upwards('metadata.json')

          unless metadata_file
            PDK.logger.warn _('Unable to determine Puppet version for module: no metadata.json present in module.')
            return
          end

          metadata = PDK::Module::Metadata.from_file(metadata_file)
        end

        metadata.validate_puppet_version_requirement!
        metadata_requirement = metadata.puppet_requirement

        # Split combined requirements like ">= 4.7.0 < 6.0.0" into their
        # component requirements [">= 4.7.0", "< 6.0.0"]
        pattern = %r{#{Gem::Requirement::PATTERN_RAW}}
        requirement_strings = metadata_requirement['version_requirement'].scan(pattern).map do |req|
          req.compact.join(' ')
        end

        gem_requirement = Gem::Requirement.create(requirement_strings)
        find_gem(gem_requirement)
      end

      private

      def parse_specified_version(version_str)
        Gem::Version.new(version_str)
      rescue ArgumentError
        raise ArgumentError, _('%{version} is not a valid version number.') % {
          version: version_str,
        }
      end

      def pe_version_map
        @pe_version_map ||= fetch_pe_version_map.map { |version_map|
          maps = version_map['versions'].map do |pe_release|
            requirements = ["= #{pe_release['version']}"]

            # Some PE release have a .0 Z release, which causes problems when
            # the user specifies "X.Y" expecting to get the latest Z and
            # instead getting the oldest.
            requirements << "!= #{pe_release['version'].gsub(%r{\.\d+\Z}, '')}" if pe_release['version'].end_with?('.0')
            {
              requirement: Gem::Requirement.create(requirements),
              gem_version: pe_release['puppet'],
            }
          end

          maps << {
            requirement: requirement_from_forge_range(version_map['release']),
            gem_version: version_map['versions'].find { |r| r['version'] == version_map['latest'] }['puppet'],
          }
        }.flatten
      end

      def fetch_pe_version_map
        map = PDK::Util::VendoredFile.new('pe_versions.json', PE_VERSIONS_URL).read

        JSON.parse(map)
      rescue PDK::Util::VendoredFile::DownloadError => e
        raise PDK::CLI::FatalError, e.message
      rescue JSON::ParserError
        raise PDK::CLI::FatalError, _('Failed to parse Puppet Enterprise version map file.')
      end

      def requirement_from_forge_range(range_str)
        Gem::Requirement.create("~> #{range_str.gsub(%r{\.x\Z}, '.0')}")
      end

      def rubygems_puppet_versions
        return @rubygems_puppet_versions unless @rubygems_puppet_versions.nil?

        fetcher = Gem::SpecFetcher.fetcher
        puppet_tuples = fetcher.detect(:released) do |spec_tuple|
          spec_tuple.name == 'puppet' && Gem::Platform.match(spec_tuple.platform)
        end
        puppet_versions = puppet_tuples.map { |name, _| name.version }.uniq
        @rubygems_puppet_versions = puppet_versions.sort { |a, b| b <=> a }
      end

      def find_gem(requirement)
        if PDK::Util.package_install?
          find_in_package_cache(requirement)
        else
          find_in_rubygems(requirement)
        end
      end

      def find_in_rubygems(requirement)
        version = rubygems_puppet_versions.find { |r| requirement.satisfied_by?(r) }
        version.nil? ? nil : { gem_version: version, ruby_version: PDK::Util::RubyVersion.default_ruby_version }
      end

      def find_in_package_cache(requirement)
        PDK::Util::RubyVersion.versions.each do |ruby_version, _|
          PDK::Util::RubyVersion.use(ruby_version)
          version = PDK::Util::RubyVersion.available_puppet_versions.find { |r| requirement.satisfied_by?(r) }
          return { gem_version: version, ruby_version: ruby_version } unless version.nil?
        end

        nil
      end
    end
  end
end
