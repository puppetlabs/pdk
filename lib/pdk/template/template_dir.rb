require 'pdk'
require 'forwardable'

module PDK
  module Template
    # A helper class representing an already fetched template on disk, with an appropriate renderer instance.
    # @see PDK::Template.with
    class TemplateDir
      # Creates an instance of TemplateDir object
      # @see TemplateDir.new
      def self.instance(uri, path, context, renderer = nil)
        new(uri, path, context, renderer)
      end

      extend Forwardable

      # Helper methods for rendering
      def_delegators :@renderer, :render, :render_single_item, :has_single_item?

      # @return [PDK::Util::TemplateURI] The URI which points to the source location of the Template
      attr_accessor :uri

      # @return [String] The path to where the template exists on disk
      attr_accessor :path

      # @return [Hash{String => String}] A hash of information about the template
      attr_accessor :metadata

      # @param template_uri [PDK::Util::TemplateUri] A URI which points to the source location of the Template
      # @param path [String] The path to where the template exists on disk
      # @param context [PDK::Context] The context in which the redering will occur in
      # @param renderer [PDK::Template::Renderer::AbstractRenderer] The an instance of a rendering class. If nil, a renderer will be created that's appropriate for the template and context
      def initialize(uri, path, context, renderer = nil)
        @uri = uri
        @path = path
        @metadata = {}

        @renderer = renderer.nil? ? Renderer.instance(uri, path, context) : renderer
        raise 'Could not find a compatible template renderer for %{path}' % { path: path } if @renderer.nil?
      end

      # Later additions may include Control Repo rendering, for example
      #
      # def render_control_repo(name, options = {})
      #   render(CONTROL_REPO_TEMPLATE_TYPE, name, options.merge(include_first_time: false)) { |*args| yield(*args) }
      # end
      #
      # def render_new_control_repo(name, repo_metadata = {}, options = {})
      #   render(CONTROL_REPO_TEMPLATE_TYPE, name, options.merge(include_first_time: true, control_repo_metadata: repo_metadata)) { |*args| yield(*args) }
      # end
      #:nocov: These are just helper methods and are tested elsewhere.

      # Render an existing module
      # @see PDK::Template::Renderer::AbstractRenderer.render
      def render_module(module_name, options = {})
        @renderer.render(MODULE_TEMPLATE_TYPE, module_name, options.merge(include_first_time: false)) { |*args| yield(*args) }
      end

      # Render a new module
      # @see PDK::Template::Renderer::AbstractRenderer.render
      def render_new_module(module_name, module_metadata = {}, options = {})
        @renderer.render(MODULE_TEMPLATE_TYPE, module_name, options.merge(include_first_time: true, module_metadata: module_metadata)) { |*args| yield(*args) }
      end
      #:nocov:
    end
  end
end
