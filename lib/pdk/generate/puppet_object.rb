require 'pdk'

module PDK
  module Generate
    class PuppetObject
      attr_reader :context
      attr_reader :object_name
      attr_reader :options

      # Initialises the PDK::Generate::PuppetObject object.
      #
      # In general, this object should never be instantiated directly. Instead,
      # one of the subclasses should be used e.g. PDK::Generate::Klass.
      #
      # New subclasses generally only need to inherit this class, set the
      # OBJECT_TYPE constant and implement the {#template_data},
      # {#target_object_path} and {#target_spec_path} methods.
      #
      # @param module_dir [String] The path to the root of module that the
      #   will contain the object.
      # @param object_name [String] The name of the object.
      # @param options [Hash{Symbol => Object}]
      def initialize(context, object_name, options)
        raise ArgumentError, 'Expected PDK::Context::AbstractContext but got \'%{klass}\' for context' % { klass: context.class } unless context.is_a?(PDK::Context::AbstractContext)
        @context = context
        @options = options
        @object_name = object_name
      end

      # Whether the generator should only return test (spec) files
      # @return [Boolean]
      def spec_only?
        @options[:spec_only]
      end

      # Subclass and implement {#friendly_name} to provide a nice name to show users in CLI
      # @abstract
      # @return String
      def friendly_name
        raise NotImplementedError
      end

      # Subclass and implement {#template_files} to provide the template files to
      #   render. Implementations of this method should return a Hash!{String => String}.
      # @abstract
      # @return Hash{String => String} Hash key is the source template file and the Hash value is
      #                                the relative destination path
      def template_files
        raise NotImplementedError
      end

      #  Subclass and implement {#template_data} to provide data to the templates during rendering.
      # @abstract
      # @return Hash{Symbol => Object}
      def template_data
        raise NotImplementedError
      end

      # Raises an error if any pre-conditions are not met
      #
      # @return [void]
      # @abstract
      def check_preconditions
        raise ArgumentError, 'Expected a module context but got %{context_name}' % { context_name: context.display_name } unless context.is_a?(PDK::Context::Module)
      end

      # Check the preconditions of this template group, behaving as a predicate rather than raising an exception.
      #
      # @return [Boolean] true if the generator is safe to run, otherwise false.
      def can_run?
        check_preconditions
        true
      rescue StandardError
        false
      end

      # Creates an instance of an update manager
      # @api private
      def update_manager_instance
        require 'pdk/module/update_manager'
        PDK::Module::UpdateManager.new
      end

      # Stages and then executes the changes for the templates to be rendereed.
      # This is the main entry point for the class.
      #
      # @see #stage_changes
      # @return [PDK::Module::UpdateManager] The update manager which implemented the changes
      # @api public
      def run(update_manager = update_manager_instance)
        stage_changes(update_manager).sync_changes!
        update_manager
      end

      # Check that the templates can be rendered. Find an appropriate template
      # and stages the target files from the template. This is the main entry
      # point for the class.
      #
      # @raise [PDK::CLI::ExitWithError] if the target files already exist.
      # @raise [PDK::CLI::FatalError] (see #render_file)
      # @return [PDK::Module::UpdateManager] The update manager with the staged changes
      # @api public
      def stage_changes(update_manager)
        check_preconditions

        with_templates do |template_dir|
          template_files.each do |source_file, relative_dest_path|
            new_content = template_dir.render_single_item(source_file, template_data)
            next if new_content.nil?

            stage_change(relative_dest_path, new_content, update_manager)
          end
        end
        non_template_files.each { |relative_dest_path, content| stage_change(relative_dest_path, content, update_manager) }

        update_manager
      end

      # Stages a single file into the Update Manager.
      # @return [void]
      # @api private
      def stage_change(relative_dest_path, content, update_manager)
        absolute_file_path = File.join(context.root_path, relative_dest_path)
        if PDK::Util::Filesystem.exist?(absolute_file_path)
          raise PDK::CLI::ExitWithError, "Unable to generate %{object_type}; '%{file}' already exists." % {
            file:        absolute_file_path,
            object_type: spec_only? ? 'unit test' : friendly_name,
          }
        end
        update_manager.add_file(absolute_file_path, content)
      end

      # A subclass may wish to stage files into the Update Manager, but the content is not templated. Subclasses
      # can override this method to stage arbitrary files
      #
      # @api private
      # @return [Hash{String => String}] A Hash with the relative file path as the key and the new file content as the value.
      # @abstract
      def non_template_files
        {}
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
        require 'pdk/logger'
        require 'pdk/util/template_uri'

        templates.each do |template|
          if template[:uri].nil?
            PDK.logger.debug('No %{dir_type} template found; trying next template directory.' % { dir_type: template[:type] })
            next
          end

          PDK::Template.with(PDK::Util::TemplateURI.new(template[:uri]), context) do |template_dir|
            if template_files.any? { |source_file, _| template_dir.has_single_item?(source_file) }
              yield template_dir
              # TODO: refactor to a search-and-execute form instead
              return # work is done # rubocop:disable Lint/NonLocalExitFromIterator
            elsif template[:allow_fallback]
              PDK.logger.debug('Unable to find a %{type} template in %{url}; trying next template directory.' % { type: friendly_name, url: template[:uri] })
            else
              raise PDK::CLI::FatalError, 'Unable to find the %{type} template in %{url}.' % { type: friendly_name, url: template[:uri] }
            end
          end
        end
      rescue ArgumentError => e
        raise PDK::CLI::ExitWithError, e
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
        require 'pdk/util/template_uri'

        @templates ||= PDK::Util::TemplateURI.templates(@options)
      end

      # Retrieves the name of the module (without the forge username) from the
      # module metadata.
      #
      # @return [String] The name of the module.
      #
      # @api private
      def module_name
        return nil unless context.is_a?(PDK::Context::Module)

        require 'pdk/util'
        @module_name ||= PDK::Util.module_metadata(context.root_path)['name'].rpartition('-').last
      rescue ArgumentError => e
        raise PDK::CLI::FatalError, e
      end

      private

      # Transform an object name into a ruby class name
      def class_name_from_object_name(object_name)
        object_name.to_s.split('_').map(&:capitalize).join
      end
    end
  end
end
