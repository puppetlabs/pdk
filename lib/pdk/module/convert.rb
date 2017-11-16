require 'pdk/generate/module'

module PDK
  module Module
    class Convert
      def self.invoke(_options)
        # TODO: Dummy template metadata, replace with TemplateDir#metadata
        template_metadata = {}

        update_metadata('metadata.json', template_metadata)

        # TODO: Diffing & confirmation

        rename_file('metadata.json.pdknew', 'metadata.json')
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
        metadata.write!("#{metadata_path}.pdknew")
      end

      def self.rename_file(source, destination)
        FileUtils.mv(source, destination)
      rescue Errno::EACCES => e
        raise PDK::CLI::FatalError, _("Failed to move '%{source}' to '%{destination}': %{message}") % {
          source:      source,
          destination: destination,
          message:     e.message,
        }
      end
    end
  end
end
