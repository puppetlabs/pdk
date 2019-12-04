require 'pdk'
require 'pdk/module/template_dir/base'

module PDK
  module Module
    module TemplateDir
      class Local < Base
        def template_path(uri)
          [uri.shell_path, false]
        end

        # For plain fileystem directories, this will return the URL to the repository only.
        #
        # @return [Hash{String => String}] A hash of identifying metadata.
        def metadata
          super.merge('template-url' => uri.bare_uri)
        end
      end
    end
  end
end
