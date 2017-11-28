require 'pdk/generate/module'
require 'pdk/module/update_manager'

module PDK
  module Module
    class Convert
      def self.invoke(options)
        # TODO: Dummy template metadata, replace with TemplateDir#metadata
        template_metadata = {}
        update_manager = PDK::Module::UpdateManager.new

        update_manager.modify_file('metadata.json', update_metadata('metadata.json', template_metadata))

        return unless update_manager.changes?

        generate_report(update_manager)

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

      def self.generate_report(update_manager)
        update_manager.changes[:modified].each do |_, diff|
          File.open('convert_report.txt', 'a') { |file| file.write(diff) }
          puts diff
        end
      end
    end
  end
end
