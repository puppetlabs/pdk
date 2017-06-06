require 'fileutils'

require 'pdk'
require 'pdk/logger'
require 'pdk/module/metadata'
require 'pdk/module/templatedir'
require 'pdk/template_file'

module PDK
  module Generate
    class PuppetObject
      attr_reader :module_dir
      attr_reader :object_name

      # Initialises the PDK::Generate::PuppetObject object.
      #
      # In general, this object should never be instantiated directly. Instead,
      # one of the subclasses should be used e.g. PDK::Generate::Klass.
      #
      # New subclasses generally only need to inherit this class, set the
      # OBJECT_TYPE constant and implement the {#template_data},
      # {#target_object_path} and {#target_spec_path} methods.
      #
      # @param module_dir [String] The path to the module directory that the
      #   will contain the object.
      # @param object_name [String] The name of the object.
      # @param options [Hash{Symbol => Object}]
      #
      # @api public
      def initialize(module_dir, object_name, options = {})
        @module_dir = module_dir
        @options = options

        if %i[class defined_type].include?(object_type)
          object_name_parts = object_name.split('::')

          @object_name = if object_name_parts.first == module_name
                           object_name
                         else
                           [module_name, object_name].join('::')
                         end
        end
      end

      # @abstract Subclass and implement {#template_data} to provide data to
      #   the templates during rendering. Implementations of this method should
      #   return a Hash[{Symbol => Object}].
      def template_data
        raise NotImplementedError
      end

      # @abstract Subclass and implement {#target_object_path}. Implementations
      #   of this method should return a String containing the destination path
      #   of the object being generated.
      def target_object_path
        raise NotImplementedError
      end

      # @abstract Subclass and implement {#target_spec_path}. Implementations
      #   of this method should return a String containing the destination path
      #   of the tests for the object being generated.
      def target_spec_path
        raise NotImplementedError
      end

      # Retrieves the type of the object being generated, e.g. :class,
      # :defined_type, etc. This is specified in the subclass' OBJECT_TYPE
      # constant.
      #
      # @return [Symbol] the type of the object being generated.
      #
      # @api private
      def object_type
        self.class::OBJECT_TYPE
      end

      # Check that the target files do not exist, find an appropriate template
      # and create the target files from the template. This is the main entry
      # point for the class.
      #
      # @raise [PDK::CLI::FatalError] if the target files already exist.
      #
      # @api public
      def run
        [target_object_path, target_spec_path].each do |target_file|
          if File.exist?(target_file)
            raise PDK::CLI::FatalError, _("Unable to generate class, '%{file}' already exists.") % { file: target_file }
          end
        end

        with_templates do |template_path, config_hash|
          data = template_data.merge(configs: config_hash)

          render_file(target_object_path, template_path[:object], data)
          render_file(target_spec_path, template_path[:spec], data) if template_path[:spec]
        end
      end

      # Render a file using the provided template and write it to disk.
      #
      # @param dest_path [String] The path that the rendered file should be
      #   written to. Any necessary directories will be automatically created.
      # @param template_path [String] The path on disk to the file containing
      #   the template.
      # @param data [Hash{Object => Object}] The data to be provided to the
      #   template when rendering.
      #
      # @return [void]
      #
      # @api private
      def render_file(dest_path, template_path, data)
        PDK.logger.info(_('Creating %{file} from template.') % { file: dest_path })
        file_content = PDK::TemplateFile.new(template_path, data).render
        FileUtils.mkdir_p(File.dirname(dest_path))
        File.open(dest_path, 'w') { |f| f.write file_content }
      end

      # Search the possible template directories in order of preference to find
      # a template that can be used to render a new object of the specified
      # type.
      #
      # @yieldparam template_paths [Hash{Symbol => String}] :object contains
      #   the path on disk to the template file for the object, :spec contains
      #   the path on disk to the template file for the tests for the object
      #   (if it exists).
      # @yieldparam config_hash [Hash{Object => Object}] the contents of the
      #   :global key in the config_defaults.yml file.
      #
      # @raise [PDK::CLI::FatalError] if no suitable template could be found.
      #
      # @api private
      def with_templates
        templates.each do |template|
          if template[:url].nil?
            PDK.logger.debug(_('No %{dir_type} template specified; trying next template directory.') % { dir_type: template[:type] })
            next
          end

          PDK::Module::TemplateDir.new(template[:url]) do |template_dir|
            template_paths = template_dir.object_template_for(object_type)

            if template_paths
              config_hash = template_dir.object_config
              yield template_paths, config_hash
              return
            else
              if template[:allow_fallback]
                PDK.logger.debug(_('Unable to find a %{type} template in %{url}, trying next template directory') % { type: object_type, url: template[:url] })
              else
                raise PDK::CLI::FatalError, _('Unable to find the %{type} template in %{url}.') % { type: object_type, url: template[:url] }
              end
            end
          end
        end
      end

      # Provides the possible template directory locations in the order in
      # which they should be searched for a valid template.
      #
      # If a template-url has been specified on in the options hash (e.g. from
      # a CLI parameter), then this template directory will be checked first
      # and we do not fall back to the next possible template directory.
      #
      # If we have not been provided a specific template directory to use, we
      # try the template specified in the module metadata (as set during
      # PDK::Generate::Module) and fall back to the default template if
      # necessary.
      #
      # @return [Array<Hash{Symbol => Object}>] an array of hashes. Each hash
      #   contains 3 keys: :type contains a String that describes the template
      #   directory, :url contains a String with the URL to the template
      #   directory, and :allow_fallback contains a Boolean that specifies if
      #   the lookup process should proceed to the next template directory if
      #   the template file is not in this template directory.
      #
      # @api private
      def templates
        @templates ||= [
          { type: 'CLI', url: @options[:'template-url'], allow_fallback: false },
          { type: 'metadata', url: module_metadata.data['template-url'], allow_fallback: true },
          { type: 'default', url: PDK::Generate::Module::DEFAULT_TEMPLATE, allow_fallback: false },
        ]
      end

      # Retrieves the name of the module (without the forge username) from the
      # module metadata.
      #
      # @raise (see #module_metadata)
      # @return [String] The name of the module.
      #
      # @api private
      def module_name
        @module_name ||= module_metadata.data['name'].rpartition('-').last
      end

      # Parses the metadata.json file for the module.
      #
      # @raise [PDK::CLI::FatalError] if the metadata.json file does not exist,
      #   can not be read, or contains invalid metadata.
      #
      # @return [PDK::Module::Metadata] the parsed module metadata.
      #
      # @api private
      def module_metadata
        @module_metadata ||= begin
          PDK::Module::Metadata.from_file(File.join(module_dir, 'metadata.json'))
        rescue ArgumentError => e
          raise PDK::CLI::FatalError, _("'%{dir}' does not contain valid Puppet module metadata; %{msg}") % { dir: module_dir, msg: e.message }
        end
      end
    end
  end
end
