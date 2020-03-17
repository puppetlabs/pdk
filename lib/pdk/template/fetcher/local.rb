require 'pdk'

module PDK
  module Template
    module Fetcher
      class Local < PDK::Template::Fetcher::AbstractFetcher
        # Whether the passed uri is fetchable. This is a catch-all and all URIs
        # are considered on-disk already.
        #
        # @see PDK::Template::Fetcher.instance
        # @return [Boolean]
        def self.fetchable?(_uri, _options = {})
          true
        end

        # @see PDK::Template::Fetcher::AbstractTemplateFetcher.fetch!
        def fetch!
          return if fetched
          super

          @path = uri.shell_path
          @temporary = false
          @metadata['template-url'] = uri.bare_uri
        end
      end
    end
  end
end
