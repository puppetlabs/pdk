require 'pdk'

module PDK
  module Template
    module Renderer
      module V1
        autoload :LegacyTemplateDir, 'pdk/template/renderer/v1/legacy_template_dir'
        autoload :Renderer, 'pdk/template/renderer/v1/renderer'
        autoload :TemplateFile, 'pdk/template/renderer/v1/template_file'

        # Whether the template directory and context are valid for the V1 renderer
        # @see PDK::Template::Renderer.instance
        def self.compatible?(template_root, _context)
          %w[moduleroot moduleroot_init].all? { |dir| PDK::Util::Filesystem.directory?(File.join(template_root, dir)) }
        end

        # Creates an instance of the V1 Renderer
        # @see PDK::Template::Renderer.instance
        def self.instance(template_root, template_uri, context)
          PDK::Template::Renderer::V1::Renderer.new(template_root, template_uri, context)
        end
      end
    end
  end
end
