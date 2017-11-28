require 'pdk/generate/module'
require 'pdk/module/update_manager'
require 'pdk/util'

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

        return unless update_manager.changes?

        [:added, :removed].each do |category|
          PDK.logger.info(_('Files to be %{category}:') % { category: category })
          update_manager.changes[category].each do |file|
            # This is where we add the entries to the report
            puts file[:path]
          end
        end

        PDK.logger.info(_('Files to be modified:'))
        update_manager.changes[:modified].each do |_, diff|
          # This is where we add the entries to the report
          puts diff
        end

        return if options[:noop]

        unless options[:force]
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
    end
  end
end
