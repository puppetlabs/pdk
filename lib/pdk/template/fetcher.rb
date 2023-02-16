require 'pdk'

module PDK
  module Template
    module Fetcher
      autoload :Git, 'pdk/template/fetcher/git'
      autoload :Local, 'pdk/template/fetcher/local'

      # Returns a Template Fetcher implementation for the given Template URI
      # @param uri [PDK::Util::TemplateURI] The URI of the template to fetch
      # @param options [Hash{Object => Object}] A list of options to pass through to the fetcher.
      #
      # @return [PDK::Template::Fetcher::AbstractTemplateFetcher] An instance of a class which implements the AbstractFetcher class
      def self.instance(uri, options = {})
        return Git.new(uri, options) if Git.fetchable?(uri, options)
        Local.new(uri, options)
      end

      # Creates an instance of a PDK::Template::Fetcher::AbstractTemplateFetcher object with the path or URL to the template
      # and the block of code to run to be run while the template is fetched.
      #
      # The fetched directory is only guaranteed to be available on disk
      # within the scope of the block passed to this method.
      #
      # @param uri [PDK::Util::TemplateURI] The URI of the template to fetch.
      # @param options [Hash{Object => Object}] A list of options to pass through to the fetcher.
      #
      # @yieldparam fetcher [PDK::Template::Fetcher::AbstractTemplateFetcher] The initialised fetcher with
      #             the template already fetched
      #
      # @example Using a git repository as a template
      #   PDK::Template::Fetcher.with('https://github.com/puppetlabs/pdk-templates') do |fetcher|
      #   end
      #
      # @raise [ArgumentError] If no block is given to this method.
      # @return [void]
      def self.with(uri, options = {})
        raise ArgumentError, '%{class_name}.with must be passed a block.' % { class_name: name } unless block_given?
        fetcher = instance(uri, options)

        begin
          fetcher.fetch!
          yield fetcher
        ensure
          # If the the path is temporary, clean it up
          PDK::Util::Filesystem.rm_rf(fetcher.path) if fetcher.temporary
        end
        nil
      end

      # An abstract class which all Template Fetchers should subclass. This class is responsible for
      # downloading or copying a Template Directory that is pointed to by a Template URI
      #
      # @api private
      # @abstract
      class AbstractFetcher
        # @return [PDK::Util::TemplateURI] The URI of the template that is to be fetched
        attr_reader :uri

        # @return [String] The local filesystem path of the fetched template
        attr_reader :path

        # @return [Boolean] Whether the fetched path should be considered temporary and be deleted after use
        attr_reader :temporary

        # @return [Boolean] Whether the template has been fetched yet
        attr_reader :fetched

        # @return [Hash] The metadata hash for this template.
        attr_reader :metadata

        # @param uri [PDK::Util::TemplateURI] The URI of the template to fetch
        # @param options [Hash{Object => Object}] A list of options to pass through to the fetcher.
        def initialize(uri, options)
          @uri = uri
          # Defaults
          @path = nil
          @metadata = {
            'pdk-version' => PDK::Util::Version.version_string,
            'template-url' => nil,
            'template-ref' => nil,
          }
          @fetched = false
          @temporary = false
          @options = options
        end

        # Fetches the template directory and populates the path property
        #
        # @return [void]
        # @abstract
        def fetch!
          @fetched = true
        end
      end
    end
  end
end
