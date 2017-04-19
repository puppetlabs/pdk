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

        module_interview(metadata, opts) unless opts[:skip_interview] # TODO: Build way to get info by answers file

        # TODO: write metadata.json, build module directory structure, and write out templates.
        PDK::CLI::Exec.execute(cmd(opts))
      end

      def self.module_interview(metadata, opts={})
        puts "We need to create a metadata.json file for this module.  Please answer the"
        puts "following questions; if the question is not applicable to this module, feel free"
        puts "to leave it blank."

        begin
          puts "\nPuppet uses Semantic Versioning (semver.org) to version modules."
          puts "What version is this module?  [#{metadata.data['version']}]"
          metadata.update('version' => PDK::CLI::Input.get(metadata.data['version']))
        rescue
          PDK.logger.error("We're sorry, we could not parse that as a Semantic Version.")
          retry
        end

        puts "\nWho wrote this module?  [#{metadata.data['author']}]"
        metadata.data.update('author' => PDK::CLI::Input.get(metadata.data['author']))

        if not opts.has_key? :license
          puts "\nWhat license does this module code fall under?  [#{metadata.data['license']}]"
          metadata.data.update('license' => PDK::CLI::Input.get(metadata.data['license']))
        end

        puts "\nHow would you describe this module in a single sentence?"
        metadata.data.update('summary' => PDK::CLI::Input.get(metadata.data['summary']))

        puts "\nWhere is this module's source code repository?"
        metadata.data.update('source' => PDK::CLI::Input.get(metadata.data['source']))

        puts "\nWhere can others go to learn more about this module?  [#{metadata.data['project_page'] || '(none)'}]"
        metadata.data.update('project_page' => PDK::CLI::Input.get(metadata.data['project_page']))

        puts "\nWhere can others go to file issues about this module? [#{metadata.data['issues_url'] || '(none)'}]"
        metadata.data.update('issues_url' => PDK::CLI::Input.get(metadata.data['issues_url']))

        puts
        puts '-' * 40
        puts metadata.to_json
        puts '-' * 40
        puts
        puts "About to generate this metadata; continue? [n/Y]"

        if PDK::CLI::Input.get('Y') !~ /^y(es)?$/i
          puts "Aborting..."
          exit 0
        end
      end
    end
  end
end
