require 'pdk'
require 'ostruct'

module PDK
  module Template
    module Renderer
      module V1
        class TemplateFile < OpenStruct
          # Initialises the TemplateFile object with the path to the template file
          # and the data to be used when rendering the template.
          #
          # @param template_file [String] The path on disk to the template file.
          # @param data [Hash{Symbol => Object}] The data that should be provided to
          # the template when rendering.
          # @option data [Object] :configs The value of this key will be provided to
          # the template as an instance variable `@configs` in order to maintain
          # compatibility with modulesync.
          #
          # @api public
          def initialize(template_file, data = {})
            @template_file = template_file

            if data.key?(:configs)
              @configs = data[:configs]
            end

            super(data)
          end

          # Renders the template by calling the appropriate engine based on the file
          # extension.
          #
          # If the template has an `.erb` extension, the content of the template
          # file will be treated as an ERB template. All other extensions are treated
          # as plain text.
          #
          # @return [String] The rendered template
          #
          # @raise (see #template_content)
          #
          # @api public
          def render
            case File.extname(@template_file)
            when '.erb'
              render_erb
            else
              render_plain
            end
          end

          def config_for(path)
            return unless respond_to?(:template_dir)

            template_dir.config_for(path)
          end

          private

          # Reads the content of the template file into memory.
          #
          # @return [String] The content of the template file.
          #
          # @raise [ArgumentError] If the template file does not exist or can not be
          # read.
          #
          # @api private
          def template_content
            if PDK::Util::Filesystem.file?(@template_file) && PDK::Util::Filesystem.readable?(@template_file)
              return PDK::Util::Filesystem.read_file(@template_file)
            end

            raise ArgumentError, "'%{template}' is not a readable file" % { template: @template_file }
          end

          # Renders the content of the template file as an ERB template.
          #
          # @return [String] The rendered template.
          #
          # @raise (see #template_content)
          #
          # @api private
          def render_erb
            require 'erb'

            renderer = ERB.new(template_content, nil, '-')
            renderer.filename = @template_file
            renderer.result(binding)
          end

          # Renders the content of the template file as plain text.
          #
          # @return [String] The rendered template.
          #
          # @raise (see #template_content)
          #
          # @api private
          def render_plain
            template_content
          end
        end
      end
    end
  end
end
