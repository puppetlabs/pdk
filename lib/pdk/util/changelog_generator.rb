require 'pdk'

module PDK
  module Util
    module ChangelogGenerator
      # Taken from the version regex in https://forgeapi.puppet.com/schemas/module.json
      VERSION_REGEX = %r{^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*)?(\+[0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*)?$}
      GEM = 'github_changelog_generator'.freeze

      # Raises if the github_changelog_generator is not available
      def self.github_changelog_generator_available!
        check_command = PDK::CLI::Exec::InteractiveCommand.new(PDK::CLI::Exec.bundle_bin, 'info', 'github_changelog_generator')
        check_command.context = :module

        result = check_command.execute!

        return if result[:exit_code].zero?

        raise PDK::CLI::ExitWithError, 'Unable to generate the changelog as the %{gem} gem is not included in this module\'s Gemfile' % { gem: GEM }
      end

      # Runs the Changelog Generator gem (in the module's context) to automatically create a CHANGLELOG.MD file
      #
      # @returns [String] The content of the new Changelog
      def self.generate_changelog
        github_changelog_generator_available!

        changelog_command = PDK::CLI::Exec::InteractiveCommand.new(PDK::CLI::Exec.bundle_bin, 'exec', 'rake', 'changelog')
        changelog_command.context = :module

        result = changelog_command.execute!
        raise PDK::CLI::ExitWithError, 'Error generating changelog: %{stdout}' % { stdout: result[:stdout] } unless result[:exit_code].zero?

        output = changelog_content

        raise PDK::CLI::ExitWithError, 'The generated changelog contains uncategorized Pull Requests. Please label them and try again. See %{changelog_file} for more details' % { changelog_file: changelog_file } if output =~ %r{UNCATEGORIZED PRS; GO LABEL THEM} # rubocop:disable Metrics/LineLength
        output
      end

      # Computes the next version, based on the content of a changelog
      #
      # @param current_version [String, Gem::Version] The current version of the module
      # @return [String] The new version. May be the same as the current version if there are no notable changes
      def self.compute_next_version(current_version)
        raise PDK::CLI::ExitWithError, 'Invalid version string %{version}' % { version: current_version } unless current_version =~ VERSION_REGEX
        version = Gem::Version.create(current_version).segments
        PDK.logger.info 'Determing the target version from \'%{file}\'' % { file: changelog_file }

        # Grab all lines that start with ## between from the latest changes
        # For example given the changelog below

        # ```
        # # Change log
        #
        # All notable changes to this project will be documented in this file.
        #
        # ## [v4.0.0](https://github.com/puppetlabs/puppetlabs-inifile/tree/v4.
        #
        # [Full Changelog](https://github.com/puppetlabs/puppetlabs-inifile/com   --+
        #                                                                           |
        # ### Changed                                                               |
        #                                                                           |
        # - pdksync - FM-8499 - remove ubuntu14 support [\#363](https://github.     |  It's this piece of text we are interested in
        #                                                                           |
        # ### Added                                                                 |
        #                                                                           |
        # - FM-8402 add debian 10 support [\#352](https://github.com/puppetlabs     |
        #                                                                           |
        # ## [v3.1.0](https://github.com/puppetlabs/puppetlabs-inifile/tree/v3.     |
        #                                                                         --+
        # [Full Changelog](https://github.com/puppetlabs/puppetlabs-inifile/com
        #
        # ### Added
        #
        # - FM-8222 - Port Module inifile to Litmus [\#344](https://github.com/
        # - \(FM-8154\) Add Windows Server 2019 support [\#340](https://github.
        # - \(FM-8041\) Add RedHat 8 support [\#339](https://github.com/puppetl
        # ````
        data = ''
        in_changelog_entry = false
        changelog_content.each_line do |line|
          line.strip!
          if line.start_with?('[')
            # We're leaving the latest changes so we can break
            break if in_changelog_entry
            in_changelog_entry = true
          end
          if in_changelog_entry && line.start_with?('##')
            data += line
          end
        end

        # Check for meta headers in first two header line matches
        if data =~ %r{^### Changed}
          # Major Version bump
          version[0] += 1
          version[1] = 0
          version[2] = 0
        elsif data =~ %r{^### Added}
          # Minor Version bump
          version[1] += 1
          version[2] = 0
        elsif data =~ %r{^### Fixed}
          # Patch Version bump
          version[2] += 1
        end

        version.join('.')
      end

      # Returns the top most version from the CHANGELOG file
      def self.latest_version
        latest = nil
        changelog_content.each_line do |line|
          line.strip!
          if line.start_with?('## [')
            latest = line[line.index('[') + 1..line.index(']') - 1].delete('v')
            break # stops after the top version is extracted
          end
        end
        latest
      end

      def self.changelog_file
        # Default Changelog file is CHANGELOG.md, but also search for the .MD prefix as well.
        @changelog_file ||= ['CHANGELOG.md', 'CHANGELOG.MD'].map { |file| PDK::Util::Filesystem.expand_path(file) }.find { |path| PDK::Util::Filesystem.file?(path) }
      end

      def self.changelog_content
        return '' if changelog_file.nil?
        PDK::Util::Filesystem.read_file(changelog_file, open_args: 'rb:utf-8')
      end
    end
  end
end
