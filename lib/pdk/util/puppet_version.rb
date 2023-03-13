require 'pdk'
require 'json'
require 'forwardable'

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
      DEFAULT_PUPPET_DEV_BRANCH = 'main'.freeze

      def puppet_dev_env
        require 'pdk/util/ruby_version'

        {
          gem_version: 'file://%{path}' % { path: puppet_dev_path },
          ruby_version: PDK::Util::RubyVersion.latest_ruby_version,
        }
      end

      def puppet_dev_path
        require 'pdk/util'

        File.join(PDK::Util.cachedir, 'src', 'puppet')
      end

      def latest_available
        latest = find_gem(Gem::Requirement.create('>= 0'))

        if latest.nil?
          raise ArgumentError, 'Unable to find a Puppet gem in current Ruby environment or from Rubygems.org.'
        end

        latest
      end

      def puppet_dev_fetched?
        !@puppet_dev_fetched.nil?
      end

      def fetch_puppet_dev(options = {})
        return if options[:run] == :once && puppet_dev_fetched?

        require 'pdk/util/git'

        # Check if the source is cloned and is a readable git repo
        unless PDK::Util::Git.remote_repo? puppet_dev_path
          # Check if the path has something in it already. Delete it and prepare for clone if so.
          if PDK::Util::Filesystem.exist? puppet_dev_path
            PDK::Util::Filesystem.delete(puppet_dev_path) if PDK::Util::Filesystem.file? puppet_dev_path
            PDK::Util::Filesystem.rm_rf(puppet_dev_path) if PDK::Util::Filesystem.directory? puppet_dev_path
          end

          PDK::Util::Filesystem.mkdir_p puppet_dev_path
          clone_result = PDK::Util::Git.git('clone', DEFAULT_PUPPET_DEV_URL, puppet_dev_path)
          return if clone_result[:exit_code].zero?

          PDK.logger.error clone_result[:stdout]
          PDK.logger.error clone_result[:stderr]
          raise PDK::CLI::FatalError, "Unable to clone git repository from '%{repo}'." % { repo: DEFAULT_PUPPET_DEV_URL }
        end

        # Fetch Updates from remote repository
        fetch_result = PDK::Util::Git.git('-C', puppet_dev_path, 'fetch', 'origin')

        unless fetch_result[:exit_code].zero?
          PDK.logger.error fetch_result[:stdout]
          PDK.logger.error fetch_result[:stderr]
          raise PDK::CLI::FatalError, "Unable to fetch from git remote at '%{repo}'." % { repo: DEFAULT_PUPPET_DEV_URL }
        end

        # Reset local repo to latest
        reset_result = PDK::Util::Git.git('-C', puppet_dev_path, 'reset', '--hard', "origin/#{DEFAULT_PUPPET_DEV_BRANCH}")

        @puppet_dev_fetched = true
        return if reset_result[:exit_code].zero?

        PDK.logger.error reset_result[:stdout]
        PDK.logger.error reset_result[:stderr]
        raise PDK::CLI::FatalError, "Unable to update git repository at '%{cachedir}'." % { cachedir: puppet_dev_path }
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
          raise ArgumentError, 'Unable to find a Puppet gem matching %{requirement}.' % {
            requirement: latest_requirement,
          }
        end

        # Only issue this warning if they requested an exact version that isn't available.
        if version.segments.length == 3
          PDK.logger.warn('Puppet %{requested_version} is not available, activating %{found_version} instead.' % {
            requested_version: version_str,
            found_version:     latest_available_gem[:gem_version].version,
          })
        end

        latest_available_gem
      end

      def from_pe_version(version_str)
        version = parse_specified_version(version_str)

        # Due to the issue with concurrent ruby in older puppet gems
        # we are locking the pe to puppet version mapping to the latest
        # puppet version that is compatible with the pe version.
        safe_versions = {
          2023 => '7.23.0',
          2021 => '7.23.0',
          2019 => '6.29.0',
        }

        gem_version = safe_versions[version.segments[0]]
        if gem_version.nil?
          raise ArgumentError, 'Unable to map Puppet Enterprise version %{pe_version} to a Puppet version.' % {
            pe_version: version_str,
          }
        end

        PDK.logger.info 'Puppet Enterprise %{pe_version} maps to Puppet %{puppet_version}.' % {
          pe_version:     version_str,
          puppet_version: gem_version,
        }

        find_gem_for(gem_version)
      end

      def from_module_metadata(metadata = nil)
        require 'pdk/module/metadata'
        require 'pdk/util'

        if metadata.nil?
          metadata_file = PDK::Util.find_upwards('metadata.json')

          unless metadata_file
            PDK.logger.warn 'Unable to determine Puppet version for module: no metadata.json present in module.'
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
        raise ArgumentError, '%{version} is not a valid version number.' % {
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
        require 'pdk/util/vendored_file'

        map = PDK::Util::VendoredFile.new('pe_versions.json', PE_VERSIONS_URL).read

        JSON.parse(map)
      rescue PDK::Util::VendoredFile::DownloadError => e
        raise PDK::CLI::FatalError, e.message
      rescue JSON::ParserError
        raise PDK::CLI::FatalError, 'Failed to parse Puppet Enterprise version map file.'
      end

      def requirement_from_forge_range(range_str)
        Gem::Requirement.create("~> #{range_str.gsub(%r{\.x\Z}, '.0')}")
      end

      def rubygems_puppet_versions
        @rubygems_puppet_versions ||= begin
          fetcher = Gem::SpecFetcher.fetcher
          puppet_tuples = fetcher.detect(:released) do |spec_tuple|
            spec_tuple.name == 'puppet' && Gem::Platform.match(spec_tuple.platform)
          end
          puppet_versions = puppet_tuples.map { |name, _| name.version }.uniq
          puppet_versions.sort { |a, b| b <=> a }
        end
      end

      def find_gem(requirement)
        require 'pdk/util'

        if PDK::Util.package_install?
          find_in_package_cache(requirement)
        else
          find_in_rubygems(requirement)
        end
      end

      def find_in_rubygems(requirement)
        require 'pdk/util/ruby_version'

        version = rubygems_puppet_versions.find { |r| requirement.satisfied_by?(r) }
        version.nil? ? nil : { gem_version: version, ruby_version: PDK::Util::RubyVersion.default_ruby_version }
      end

      def find_in_package_cache(requirement)
        require 'pdk/util/ruby_version'

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
