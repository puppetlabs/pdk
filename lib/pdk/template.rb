require 'pdk'

module PDK
  module Template
    autoload :Fetcher, 'pdk/template/fetcher'
    autoload :Renderer, 'pdk/template/renderer'
    autoload :TemplateDir, 'pdk/template/template_dir'

    MODULE_TEMPLATE_TYPE = :module_template

    # Creates a TemplateDir object with the path or URL to the template
    # and the block of code to run to be run while the template is available.
    #
    # The template directory is only guaranteed to be available on disk
    # within the scope of the block passed to this method.
    #
    # @param uri [PDK::Util::TemplateURI] The path to a directory to use as the
    # template or a URI to a git repository.
    #
    # @param context [PDK::Context::AbstractContext] The context in which the template will render to
    #
    # @yieldparam self [PDK::Template::TemplateDir] The initialised object with
    # the template available on disk.
    #
    # @example Using a git repository as a template
    #   PDK::Template.with('https://github.com/puppetlabs/pdk-templates') do |t|
    #     t.render_module('module, PDK.context) do |filename, content, status|
    #       File.open(filename, 'w') do |file|
    #         ...
    #       end
    #     end
    #   end
    #
    # @raise [ArgumentError] If no block is given to this method.
    # @raise [PDK::CLI::FatalError]
    # @raise [ArgumentError]
    #
    # @api public
    def self.with(uri, context)
      unless block_given?
        raise ArgumentError, '%{class_name}.with must be passed a block.' % { class_name: name }
      end
      unless uri.is_a? PDK::Util::TemplateURI
        raise ArgumentError, '%{class_name}.with must be passed a PDK::Util::TemplateURI, got a %{uri_type}' % { uri_type: uri.class, class_name: name }
      end

      Fetcher.with(uri) do |fetcher|
        template_dir = TemplateDir.instance(uri, fetcher.path, context)
        template_dir.metadata = fetcher.metadata

        template_type = uri.default? ? 'default' : 'custom'
        PDK.analytics.event('TemplateDir', 'initialize', label: template_type)

        yield template_dir
      end
      nil
    end
  end
end
