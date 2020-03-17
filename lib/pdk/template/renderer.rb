require 'pdk'

module PDK
  module Template
    module Renderer
      autoload :V1, 'pdk/template/renderer/v1'

      # Returns the most appropriate renderer for the given Template Directory and Context
      #
      # @param template_root [String] The path to where the template exists on disk
      # @param template_uri [PDK::Util::TemplateUri] A URI which points to the source location of the Template
      # @param context [PDK::Context] The context in which the redering will occur in
      #
      # @return [AbstractRenderer, nil] An instance of an AbstractRenderer subclass. Returns nil if no renderer could be found
      def self.instance(template_uri, template_root, context)
        return V1.instance(template_root, template_uri, context) if V1.compatible?(template_root, context)
        nil
      end

      # An abstract class which all Template Renderers should subclass and implement. This class is responsible for
      # rendering a template or a single item within a template directory
      #
      # To implement a new renderer:
      # 1. Create a new class which subclasses AbstractRenderer and implements the public methods (has_single_item?, render and render_single_item)
      # 2. Add class methods .compatible? and .instance which are used to detect if a template is compatible with the new renderer
      #    and create an instance of the new renderer respectively
      # 3. Update the PDK::Template::Renderer.instance method to detect and create an instance of the new renderer (using the .compatible? and .instance methods
      #    created in step 2).
      #
      # See the PDK::Template::Renderer::V1 module and classes for an example on how to to this.
      #
      # @api private
      # @abstract
      class AbstractRenderer
        # @return [String] The path to where the template exists on disk
        attr_reader :template_root

        # @return [PDK::Util::TemplateURI] The URI which points to the source location of the Template
        attr_reader :template_uri

        # @return context [PDK::Context] The context in which the redering will occur in
        attr_reader :context

        # @param template_root [String] The path to where the template exists on disk
        # @param template_uri [PDK::Util::TemplateUri] A URI which points to the source location of the Template
        # @param context [PDK::Context] The context in which the redering will occur in
        def initialize(template_root, template_uri, context)
          @template_root = template_root
          @template_uri = template_uri
          @context = context
        end

        # Whether the renderer supports rendering the a single item called 'item_path'. This is used when rendering things like a new Task or a new Puppet Classes.
        # Rendering a single item is different than redering an entire project, like a entire Puppet Module or Control Repo.
        #
        # @param item_path [String] The path to the item to check
        #
        # @return [Boolean] Whether the renderer can render the item
        # @abstract
        def has_single_item?(_item_path) # rubocop:disable Naming/PredicateName Changing the method name to `single_item?` will convey the wrong intent
          false
        end

        # Loop through the files in the template type, yielding each rendered file to the supplied block.
        #
        # @param template_type [PDK::Template::*_TEMPLATE_TYPE] The type of template to render
        # @param name [String] The name to use in the rendering process
        # @param options [Hash{Object => Object}] A list of options to pass through to the renderer. See PDK::Template::TemplateDir helper methods for other options
        # @option options [Boolean] :include_first_time Whether to include "first time" items when rendering the project. While it is up to the renderer to implement this
        #                                               the expected behavior is that if the item already exists, it will not be rendererd again.  Unlike normal items which
        #                                               are always rendered to keep them in-sync
        #
        # @yieldparam dest_path [String] The path of the destination file, relative to the root of the context.
        # @yieldparam dest_content [String] The rendered content of the destination file.
        # @yieldparam dest_status [Symbol] :unmanage, :delete, :init, :manage
        #
        # @see PDK::Template::TemplateDir.render
        #
        # @return [void]
        # @abstract
        def render(template_type, name, options = {}); end

        # Render a single item and return the resulting string. This is used when rendering things like a new Task or a new Puppet Classes.
        # Rendering a single item is different than redering an entire project, like a entire Puppet Module or Control Repo. This method is
        # used in conjunction with .has_single_item?
        #
        # @param item_path [String] The path of the single item to render
        # @param template_data_hash [Hash{Object => Object}] A hash of information which will be used in the rendering process
        #
        # @return [String, Nil] The rendered content, or nil of the file could not be rendered
        # @abstract
        def render_single_item(item_path, template_data_hash = {}); end
      end
    end
  end
end
