module PDK
  module Build
    class Changelog
      def self.build(module_dir)
        require 'github_changelog_generator'
        pdk_options = {
          verbose: true,
          release_branch: 'release',
          # XXX Gonna need to make that better
          future_release: YAML.load_file('metadata.json')['version'],
          header: "# Changelog\n\nAll notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).",
          # All PRs should be labeled.
          add_pr_wo_labels: true,
          # We don't deal with issues, just PRs.
          issues: false,
          # 'maintenance' label is excluded from changelog.
          exclude_labels: ['maintenance'],
          # Make it obvious what prep work remains.
          merge_prefix: '### UNCATEGORIZED PRS; GO LABEL THEM',
          # Configure standard sections as per http://keepachangelog.com/ but without
          # security/deprecated/removed sections as they do not conform to SemVer.
          configure_sections: {
            'Changed' => {
              'prefix' => '### Changed',
              'labels' => ['backwards-incompatible'],
            },
            'Added' => {
              'prefix' => '### Added',
              'labels' => ['feature'],
            },
            'Fixed' => {
              'prefix' => '### Fixed',
              'labels' => ['bugfix'],
            },
          },
        }
        # if .github_changelog_generator exists then use that, else ask
        # question about the since_version and make the file
        unless File.exist?(File.join(module_dir, '.github_changelog_generator'))
          File.open(File.join(module_dir, '.github_changelog_generator'), 'w') do |f|
            f.write "user=puppetlabs\n"
            f.write "project=#{YAML.load_file('metadata.json')['name']}\n"
            f.write "since_tag=5.3.0\n"
          end
        end

        options = GitHubChangelogGenerator::Parser.default_options

        pdk_options.each do |k,v|
          options[k] = v
        end
        # Updates options in-place
        GitHubChangelogGenerator::ParserFile.new(options).parse!
        generator = GitHubChangelogGenerator::Generator.new options

        log = generator.compound_changelog

        output_filename = (options[:output]).to_s
        File.open(output_filename, 'w') { |file| file.write(log) }
        puts 'Done!'
        puts "Generated log placed in #{Dir.pwd}/#{output_filename}"
      rescue Errno::ENOENT
        raise 'Could not find file metadata.json; cannot generate changelog'
      rescue LoadError
        raise 'Install github_changelog_generator to get access to automatic changelog generation'
      end
    end
  end
end
