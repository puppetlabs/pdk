require 'pdk/generate/module'
require 'pdk/module/update_manager'
require 'pdk/util'
require 'pdk/report'

module PDK
  module Module
    class Convert
      def self.invoke(options)
        # TODO: Dummy template metadata, replace with TemplateDir#metadata
        template_metadata = {}
        update_manager = PDK::Module::UpdateManager.new
        template_url = options.fetch(:'template-url', PDK::Util.default_template_url)

        update_manager.modify_file('metadata.json', update_metadata('metadata.json', template_metadata))

        PDK::Module::TemplateDir.new(template_url, nil, false) do |templates|
          templates.render do |file_path, file_content|
            if File.exist? file_path
              update_manager.modify_file(file_path, file_content)
            else
              update_manager.add_file(file_path, file_content)
            end
          end
        end

        unless update_manager.changes?
          PDK::Report.default_target.puts(_('No changes required.'))
          return
        end

        # Print the summary to the default target of reports
        print_summary(update_manager)

        # Generates the full convert report
        fullreport(update_manager)

        return if options[:noop]

        unless options[:force]
          PDK.logger.info _('Please review the changes above before continuing.')
          continue = PDK::CLI::Util.prompt_for_yes(_('Do you want to continue and make these changes to your module?'))
          return unless continue
        end

        update_manager.sync_changes!
      end

      def self.update_metadata(metadata_path, template_metadata)
        if File.file?(metadata_path)
          if File.readable?(metadata_path)
            begin
              metadata = PDK::Module::Metadata.from_file(metadata_path)
              new_values = PDK::Module::Metadata::DEFAULTS.reject { |key, _| metadata.data.key?(key) }
              metadata.update!(new_values)
            rescue ArgumentError
              metadata = PDK::Generate::Module.prepare_metadata
            end
          else
            raise PDK::CLI::ExitWithError, _('Unable to convert module metadata; %{path} exists but it is not readable.') % {
              path: metadata_path,
            }
          end
        elsif File.exist?(metadata_path)
          raise PDK::CLI::ExitWithError, _('Unable to convert module metadata; %{path} exists but it is not a file.') % {
            path: metadata_path,
          }
        else
          metadata = PDK::Generate::Module.prepare_metadata
        end

        metadata.update!(template_metadata)
        metadata.to_json
      end

      def self.print_summary(update_manager)
        summary = {}
        update_manager.changes.each do |category, update_category|
          updated_files = if update_category.respond_to?(:keys)
                            update_category.keys
                          else
                            update_category.map { |file| file[:path] }
                          end

          summary[category] = updated_files.length

          next if updated_files.empty?

          PDK::Report.default_target.puts(_("\n%{banner}") % { banner: generate_banner("Files #{category}") })
          PDK::Report.default_target.puts(updated_files)
        end

        summary_to_print = summary.map { |k, v| "#{v} files #{k}" unless v < 1 }.compact
        PDK::Report.default_target.puts(_("\n%{banner}") % { banner: generate_banner('') }) unless summary_to_print.empty?
        PDK::Report.default_target.puts(_("\n%{summary}") % { summary: "#{summary_to_print.join(', ')}." })
      end

      def self.fullreport(update_manager)
        File.open('convert_report.txt', 'w')
        update_manager.changes[:modified].each do |_, diff|
          File.open('convert_report.txt', 'a') { |f| f.write("\n\n\n" + diff) }
        end
        PDK::Report.default_target.puts(_('You can find detailed differences in convert_report.txt.'))
      end

      def self.generate_banner(text)
        width = 80 # 80char banner
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
