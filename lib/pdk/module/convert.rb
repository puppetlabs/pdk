require 'pdk/generate/module'
require 'pdk/module/update_manager'
require 'pdk/util'
require 'pdk/report'

module PDK
  module Module
    class Convert
      def self.invoke(options)
        new(options).run
      end

      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def convert?
        instance_of?(PDK::Module::Convert)
      end

      def run
        stage_changes!

        unless update_manager.changes?
          if adding_tests?
            add_tests!
          else
            PDK::Report.default_target.puts(_('No changes required.'))
          end

          return
        end

        print_summary

        full_report('convert_report.txt') unless update_manager.changes[:modified].empty?

        return if noop?

        unless force?
          PDK.logger.info _(
            'Module conversion is a potentially destructive action. ' \
            'Ensure that you have committed your module to a version control ' \
            'system or have a backup, and review the changes above before continuing.',
          )
          continue = PDK::CLI::Util.prompt_for_yes(_('Do you want to continue and make these changes to your module?'))
          return unless continue
        end

        # Remove these files straight away as these changes are not something that the user needs to review.
        if needs_bundle_update?
          update_manager.unlink_file('Gemfile.lock')
          update_manager.unlink_file(File.join('.bundle', 'config'))
        end

        update_manager.sync_changes!

        PDK::Util::Bundler.ensure_bundle! if needs_bundle_update?

        add_tests! if adding_tests?

        print_result 'Convert completed'
      end

      def noop?
        options[:noop]
      end

      def force?
        options[:force]
      end

      def add_tests?
        options[:'add-tests']
      end

      def adding_tests?
        add_tests? && missing_tests?
      end

      def missing_tests?
        test_generators.any? { |gen| gen.can_run? }
      end

      def test_generators
        return @test_generators unless @test_generators.nil?

        test_gens = PDK::Util::PuppetStrings.all_objects.map do |generator, objects|
          (objects || []).map do |obj|
            generator.new(Dir.pwd, obj['name'], spec_only: true)
          end
        end

        @test_generators = test_gens.flatten
      end

      def add_tests!
        test_generators.each do |gen|
          gen.run if gen.can_run?
        end
      end

      def needs_bundle_update?
        update_manager.changed?('Gemfile')
      end

      def stage_changes!
        metadata_path = 'metadata.json'

        PDK::Module::TemplateDir.new(template_uri, nil, true) do |templates|
          new_metadata = update_metadata(metadata_path, templates.metadata)
          templates.module_metadata = new_metadata.data unless new_metadata.nil?

          if options[:noop] && new_metadata.nil?
            update_manager.add_file(metadata_path, '')
          elsif PDK::Util::Filesystem.file?(metadata_path)
            update_manager.modify_file(metadata_path, new_metadata.to_json)
          else
            update_manager.add_file(metadata_path, new_metadata.to_json)
          end

          templates.render do |file_path, file_content, file_status|
            case file_status
            when :unmanage
              PDK.logger.debug(_("skipping '%{path}'") % { path: file_path })
            when :delete
              update_manager.remove_file(file_path)
            when :init
              if convert? && !PDK::Util::Filesystem.exist?(file_path)
                update_manager.add_file(file_path, file_content)
              end
            when :manage
              if PDK::Util::Filesystem.exist?(file_path)
                update_manager.modify_file(file_path, file_content)
              else
                update_manager.add_file(file_path, file_content)
              end
            end
          end
        end
      rescue ArgumentError => e
        raise PDK::CLI::ExitWithError, e
      end

      def update_manager
        @update_manager ||= PDK::Module::UpdateManager.new
      end

      def template_uri
        @template_uri ||= PDK::Util::TemplateURI.new(options)
      end

      def update_metadata(metadata_path, template_metadata)
        if PDK::Util::Filesystem.file?(metadata_path)
          unless PDK::Util::Filesystem.readable?(metadata_path)
            raise PDK::CLI::ExitWithError, _('Unable to update module metadata; %{path} exists but it is not readable.') % {
              path: metadata_path,
            }
          end

          begin
            metadata = PDK::Module::Metadata.from_file(metadata_path)
            new_values = PDK::Module::Metadata::DEFAULTS.select do |key, _|
              !metadata.data.key?(key) || metadata.data[key].nil? ||
                (key == 'requirements' && metadata.data[key].empty?)
            end
            metadata.update!(new_values)
          rescue ArgumentError
            metadata = PDK::Generate::Module.prepare_metadata(options) unless options[:noop]
          end
        elsif PDK::Util::Filesystem.exist?(metadata_path)
          raise PDK::CLI::ExitWithError, _('Unable to update module metadata; %{path} exists but it is not a file.') % {
            path: metadata_path,
          }
        else
          return if options[:noop]

          project_dir = File.basename(Dir.pwd)
          options[:module_name] = project_dir.split('-', 2).compact[-1]
          options[:prompt] = false
          options[:'skip-interview'] = true if options[:force]

          metadata = PDK::Generate::Module.prepare_metadata(options)
        end

        metadata.update!(template_metadata)
        metadata
      end

      def summary
        summary = {}
        update_manager.changes.each do |category, update_category|
          if update_category.respond_to?(:keys)
            updated_files = update_category.keys
          else
            begin
              updated_files = update_category.map { |file| file[:path] }
            rescue TypeError
              updated_files = update_category.to_a
            end
          end

          summary[category] = updated_files
        end

        summary
      end

      def print_summary
        footer = false

        summary.keys.each do |category|
          next if summary[category].empty?

          PDK::Report.default_target.puts(_("\n%{banner}") % { banner: generate_banner("Files to be #{category}", 40) })
          PDK::Report.default_target.puts(summary[category])
          footer = true
        end

        PDK::Report.default_target.puts(_("\n%{banner}") % { banner: generate_banner('', 40) }) if footer
      end

      def print_result(banner_text)
        PDK::Report.default_target.puts(_("\n%{banner}") % { banner: generate_banner(banner_text, 40) })
        summary_to_print = summary.map { |k, v| "#{v.length} files #{k}" unless v.empty? }.compact
        PDK::Report.default_target.puts(_("\n%{summary}\n\n") % { summary: "#{summary_to_print.join(', ')}." })
      end

      def full_report(path)
        File.open(path, 'w') do |f|
          f.write("/* Report generated by PDK at #{Time.now} */")
          update_manager.changes[:modified].each do |_, diff|
            f.write("\n\n\n" + diff)
          end
          f.write("\n")
        end
        PDK::Report.default_target.puts(_("\nYou can find a report of differences in %{path}.\n\n") % { path: path })
      end

      def generate_banner(text, width = 80)
        padding = width - text.length
        banner = ''
        padding_char = '-'

        (padding / 2.0).ceil.times { banner << padding_char }
        banner << text
        (padding / 2.0).floor.times { banner << padding_char }

        banner
      end
    end
  end
end
