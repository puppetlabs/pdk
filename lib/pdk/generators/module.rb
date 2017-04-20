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
        metadata = PDK::Module::Metadata.new(
          {
            'name' => name,
            'version' => '0.1.0',
            'dependencies' => [
              { 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 1.0.0' }
            ]
          }
        )

        module_interview(metadata) unless opts[:skip_interview] # TODO: Build way to get info by answers file

        # TODO: write metadata.json, build module directory structure, and write out templates.
        PDK::CLI::Exec.execute(cmd(opts))
      end

      def self.module_interview(metadata)
        # TODO: make this one string and have a helper function to wrap
        puts _("We need to create a metadata.json file for this module. Please answer the")
        puts _("following questions; if the question is not applicable to this module, feel free")
        puts _("to leave it blank.")

        begin
          puts "\n" + _("Puppet uses Semantic Versioning (semver.org) to version modules.")
          puts _("What version is this module? [%{default_version}]") % {default_version: metadata.data['version']}
          metadata.update('version' => PDK::CLI::Input.get(metadata.data['version']))
        rescue
          PDK.logger.error(_("We're sorry, we could not parse that as a Semantic Version."))
          retry
        end

        puts "\n" + _("Who wrote this module? [%{default_author}]") % {default_author: metadata.data['author']}
        metadata.data.update('author' => PDK::CLI::Input.get(metadata.data['author']))

        puts "\n" + _("What license does this module code fall under? [%{default_license}]") % {default_license: metadata.data['license']}
        metadata.data.update('license' => PDK::CLI::Input.get(metadata.data['license']))

        puts "\n" + _("How would you describe this module in a single sentence?")
        metadata.data.update('summary' => PDK::CLI::Input.get(metadata.data['summary']))

        puts "\n" + _("Where is this module's source code repository?")
        metadata.data.update('source' => PDK::CLI::Input.get(metadata.data['source']))

        puts "\n" + _("Where can others go to learn more about this module? [%{default_project_page}]") % {default_project_page: (metadata.data['project_page'] || '(none)')}
        metadata.data.update('project_page' => PDK::CLI::Input.get(metadata.data['project_page']))

        puts "\n" + _("Where can others go to file issues about this module? [%{default_issues_url}]") % {default_issues_url: (metadata.data['issues_url'] || '(none)')}
        metadata.data.update('issues_url' => PDK::CLI::Input.get(metadata.data['issues_url']))

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
