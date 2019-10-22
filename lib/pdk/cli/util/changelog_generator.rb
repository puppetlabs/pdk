require 'bundler'

module PDK
  module CLI
    module Util
      class ChangelogGenerator
        def generate_changelog
          raise 'github_changelog_generator gem not installed' unless Bundler.rubygems.find_name('github_changelog_generator').any?
          changelog_command = PDK::CLI::Exec::InteractiveCommand.new(PDK::CLI::Exec.bundle_bin, 'exec', 'rake', 'changelog')
          changelog_command.context = :module

          result = changelog_command.execute!
          raise "Error generating changelog: #{result[:stdout]}" if result[:exit_code] != 0

          output = PDK::Util::Filesystem.read_file('CHANGELOG.md')

          raise 'Uncategorized PRs; Please go label them -> see CHANGELOG.md for details' if output =~ %r{UNCATEGORIZED PRS; GO LABEL THEM}
        end

        def get_next_version(current_version)
          current_version_map = current_version.split('.').map { |v| v.to_i }
          PDK.logger.info _('Extracting target version from CHANGELOG.md')

          # Grab all lines that start with ## between two lines that start with the version to detect changes
          data = ''
          matches = 1

          output = PDK::Util::Filesystem.read_file('CHANGELOG.MD')

          output.each_line do |line|
            break if matches > 2
            if line.start_with?('[')
              matches += 1
            end
            if line.start_with?('##')
              data += line
            end
          end

          # Check for meta headers in first two header line matches
          case data
          when %r{^### Changed}
            current_version_map[0] += 1
            current_version_map[1] = 0
            current_version_map[2] = 0
          when %r{^### Added}
            current_version_map[1] += 1
            current_version_map[2] = 0
          when %r{^### Fixed}
            current_version_map[2] += 1
          else
            PDK.logger.error _('No notable changes to release')
          end

          current_version_map.join('.')
        end
      end
    end
  end
end
