require 'pdk'
require 'pdk/logger'
require 'pdk/module/metadata'
require 'pdk/cli/exec'
require 'pdk/cli/input'

module PDK
  module Generate
    class Module
      def self.cmd(opts={})
        # TODO
        cmd = 'pwd'
        cmd
      end

      def self.invoke(name, opts={})
        defaults = {
          'name' => name,
          'version' => '0.1.0',
          'dependencies' => [
            { 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 1.0.0' }
          ]
        }

        defaults['license'] = opts[:license] if opts.has_key? :license

        metadata = PDK::Module::Metadata.new(defaults)

        module_interview(metadata, opts) unless opts[:'skip-interview'] # TODO: Build way to get info by answers file

        # TODO: write metadata.json, build module directory structure, and write out templates.
        PDK::CLI::Exec.execute(cmd(opts))
      end

      def self.module_interview(metadata, opts={})
        puts _(
          "We need to create a metadata.json file for this module. Please answer the " +
          "following questions; if the question is not applicable to this module, feel free " +
          "to leave it blank."
        )

        begin
          if metadata.data['name'].nil?
            puts "\n" + _("What is the name of your module?")
            metadata.update!('name' => PDK::CLI::Input.get())
          end
        rescue StandardError => e
          PDK.logger.error(_("We're sorry, we could not parse that as a module name: %{message}") % {message: e.message})
          retry
        end

        begin
          puts "\n" + _("Puppet uses Semantic Versioning (semver.org) to version modules.")
          puts _("What version is this module? [%{default_version}]") % {default_version: metadata.data['version']}
          metadata.update!('version' => PDK::CLI::Input.get(metadata.data['version']))
        rescue StandardError => e
          PDK.logger.error(_("We're sorry, we could not parse that as a Semantic Version: %{message}") % {message: e.message})
          retry
        end

        puts "\n" + _("Who wrote this module? [%{default_author}]") % {default_author: metadata.data['author']}
        metadata.update!('author' => PDK::CLI::Input.get(metadata.data['author']))

        if not opts.has_key? :license
          puts "\n" + _("What license does this module code fall under? [%{default_license}]") % {default_license: metadata.data['license']}
          metadata.update!('license' => PDK::CLI::Input.get(metadata.data['license']))
        end

        puts "\n" + _("How would you describe this module in a single sentence?")
        metadata.update!('summary' => PDK::CLI::Input.get(metadata.data['summary']))

        puts "\n" + _("Where is this module's source code repository?")
        metadata.update!('source' => PDK::CLI::Input.get(metadata.data['source']))

        puts "\n" + _("Where can others go to learn more about this module? [%{default_project_page}]") % {default_project_page: (metadata.data['project_page'] || '(none)')}
        metadata.update!('project_page' => PDK::CLI::Input.get(metadata.data['project_page']))

        puts "\n" + _("Where can others go to file issues about this module? [%{default_issues_url}]") % {default_issues_url: (metadata.data['issues_url'] || '(none)')}
        metadata.update!('issues_url' => PDK::CLI::Input.get(metadata.data['issues_url']))

        puts
        puts '-' * 40
        puts metadata.to_json
        puts '-' * 40
        puts
        puts _("About to generate this metadata; continue? [n/Y]")

        if PDK::CLI::Input.get('Y') !~ /^y(es)?$/i
          puts _("Aborting...")
          exit 0
        end
      end
    end
  end
end
