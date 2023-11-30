require 'pdk'
require 'uri'
require_relative './pre_build'

module PDK
  module Module
    class Release
      def self.invoke(module_path, options = {})
        new(module_path, options).run
      end

      attr_reader :options, :module_path

      def initialize(module_path, options = {})
        @options = options

        # TODO: Currently the release process can ONLY be run if the working directory IS the module root. However, in the future
        # this WILL change, so we have the API arguments for it, but only accept `nil` for the first parameter
        raise PDK::CLI::ExitWithError, 'Running the release process outside of the working directory is not supported' unless module_path.nil?

        if module_path.nil?
          module_path = PDK::Util.module_root
          raise PDK::CLI::ExitWithError, 'The module release process requires a valid module path' if module_path.nil?
        end
        raise PDK::CLI::ExitWithError, format('%{module_path} is not a valid module', module_path: module_path) unless PDK::Util.in_module_root?(module_path)

        @module_path = module_path
      end

      def run
        extend PreBuild

        # Pre-release checks
        unless force?
          raise PDK::CLI::ExitWithError, 'The module is not PDK compatible' if requires_pdk_compatibility? && !pdk_compatible?
          raise PDK::CLI::ExitWithError, 'The module is not Forge compatible' if requires_forge_compatibility? && !forge_compatible?
        end

        # Note that these checks are duplicated in the run_publish method, however it's a much better
        # experience to fail early, than going through the whole process, only to error at the end knowing full well
        # it'll fail anyway.
        validate_publish_options!

        run_validations(options) unless skip_validation?

        PDK.logger.info format('Releasing %{module_name} - from version %{module_version}', module_name: module_metadata.data['name'], module_version: module_metadata.data['version'])

        PDK::Util::ChangelogGenerator.generate_changelog unless skip_changelog?

        # Calculate the new module version
        new_version = specified_version
        new_version = PDK::Util::ChangelogGenerator.compute_next_version(module_metadata.data['version']) if new_version.nil? && !skip_changelog?
        new_version = module_metadata.data['version'] if new_version.nil? || !new_version

        if new_version != module_metadata.data['version']
          PDK.logger.info format('Updating version to %{module_version}', module_version: new_version)

          # Set the new version in metadata file
          module_metadata.data['version'] = new_version
          write_module_metadata!

          # Update the changelog with the correct version
          PDK::Util::ChangelogGenerator.generate_changelog unless skip_changelog?

          # Check if the versions match
          latest_version = PDK::Util::ChangelogGenerator.latest_version
          if !latest_version && (new_version != latest_version)
            raise PDK::CLI::ExitWithError, format('%{new_version} does not match %{latest_version}', new_version: new_version, latest_version: latest_version)
          end
        end

        run_documentation(options) unless skip_documentation?

        run_dependency_checker(options) unless skip_dependency?

        if skip_build?
          # Even if we're skipping the build, we still need the name of the tarball
          # Use the specified package path if set
          package_file = specified_package if package_file.nil?
          # Use the default as a last resort
          package_file = default_package_filename if package_file.nil?
        else
          package_file = run_build(options)
        end

        run_publish(options.dup, package_file) unless skip_publish?
      end

      def module_metadata
        @module_metada ||= PDK::Module::Metadata.from_file(File.join(module_path, 'metadata.json'))
      end

      def write_module_metadata!
        module_metadata.write!(File.join(module_path, 'metadata.json'))
        clear_cached_data
      end

      def default_package_filename
        return @default_tarball_filename unless @default_tarball_filename.nil?

        builder = PDK::Module::Build.new(module_dir: module_path)
        @default_tarball_filename = builder.package_file
      end

      # @return [String] Path to the built tarball
      def run_build(opts)
        PDK::Module::Build.invoke(opts.dup)
      end

      def run_publish(_opts, tarball_path)
        validate_publish_options!
        raise PDK::CLI::ExitWithError, format('Module tarball %{tarball_path} does not exist', tarball_path: tarball_path) unless PDK::Util::Filesystem.file?(tarball_path)

        # TODO: Replace this code when the upload functionality is added to the forge ruby gem
        require 'base64'
        file_data = Base64.encode64(PDK::Util::Filesystem.read_file(tarball_path, open_args: 'rb'))

        PDK.logger.info 'Uploading tarball to puppet forge...'
        uri = URI(forge_upload_url)
        require 'net/http'
        request = Net::HTTP::Post.new(uri.path)
        request['Authorization'] = "Bearer #{forge_token}"
        request['Content-Type'] = 'application/json'
        data = { file: file_data }

        require 'json'
        request.body = data.to_json

        require 'openssl'
        use_ssl = uri.instance_of?(URI::HTTPS)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl) do |http|
          http.request(request)
        end

        unless response.is_a?(Net::HTTPSuccess)
          PDK.logger.debug "Puppet Forge response: #{response.body}"
          raise PDK::CLI::ExitWithError, "Authentication failure when uploading to Puppet Forge: #{JSON.parse(response.body)['error']}" if response.is_a?(Net::HTTPUnauthorized)

          raise PDK::CLI::ExitWithError "Error uploading to Puppet Forge: #{JSON.parse(response.body)['message']}"

        end

        PDK.logger.info 'Publish to Forge was successful'
      end

      def validate_publish_options!
        return if skip_publish?
        raise PDK::CLI::ExitWithError, 'Missing forge-upload-url option' unless forge_upload_url
        raise PDK::CLI::ExitWithError, 'Missing forge-token option' unless forge_token
      end

      def force?
        options[:force]
      end

      def skip_build?
        options[:'skip-build']
      end

      def skip_changelog?
        options[:'skip-changelog']
      end

      def skip_dependency?
        options[:'skip-dependency']
      end

      def skip_documentation?
        options[:'skip-documentation']
      end

      def skip_publish?
        options[:'skip-publish']
      end

      def skip_validation?
        options[:'skip-validation']
      end

      def specified_version
        options[:version]
      end

      def specified_package
        options[:file]
      end

      def forge_token
        options[:'forge-token']
      end

      def forge_upload_url
        options[:'forge-upload-url']
      end

      def requires_pdk_compatibility?
        # Validation, Changelog and Dependency checks require the
        # module to be PDK Compatible
        !(skip_validation? && skip_changelog? && skip_dependency?)
      end

      def requires_forge_compatibility?
        # Pushing to the for requires the metadata to be forge compatible
        !skip_publish?
      end

      # :nocov:
      # These are just convenience methods and are tested elsewhere
      def forge_compatible?
        module_metadata.forge_ready?
      end

      def pdk_compatible?
        return @pdk_compatible unless @pdk_compatible.nil?

        builder = PDK::Module::Build.new(module_dir: module_path)
        @pdk_compatible = builder.module_pdk_compatible?
      end
      # :nocov:

      private

      def clear_cached_data
        @module_metadata = nil
        @pdk_compatible = nil
        @default_tarball_filename = nil
      end
    end
  end
end
