require 'pdk'

module PDK
  module Util
    class TemplateURI
      SCP_PATTERN = %r{\A(?!\w+://)(?:(?<user>.+?)@)?(?<host>[^:/]+):(?<path>.+)\z}

      PACKAGED_TEMPLATE_KEYWORD = 'pdk-default'.freeze
      DEPRECATED_TEMPLATE_URL = 'https://github.com/puppetlabs/pdk-module-template'.freeze
      PDK_TEMPLATE_URL = 'https://github.com/puppetlabs/pdk-templates'.freeze

      LEGACY_PACKAGED_TEMPLATE_PATHS = {
        'windows' => 'file:///C:/Program Files/Puppet Labs/DevelopmentKit/share/cache/pdk-templates.git',
        'macos'   => 'file:///opt/puppetlabs/pdk/share/cache/pdk-templates.git',
        'linux'   => 'file:///opt/puppetlabs/pdk/share/cache/pdk-templates.git',
      }.freeze

      # XXX Previously
      # - template_uri used to get the string form of the uri when generating the module and written to pdk answers and metadata
      # - template_path or deuri_path used for humans to see and commands to run
      # - uri_path used only internally by the template selection code; move out
      # - template_ref used by git checkout
      attr_reader :uri

      # input/output formats:
      #
      # file:///c:/foo (git clone location)
      # c:/foo (shell paths)
      # file:///c:/foo#main (only for metadata)
      # c:/foo#main (only for metadata)
      #
      # non output formats:
      #
      # /c:/foo (internal use only)
      # /c:/foo#main (internal use only)
      #
      def initialize(opts_or_uri)
        require 'addressable'
        # If a uri string is passed, skip the valid uri finding code.
        @uri = if opts_or_uri.is_a?(self.class)
                 opts_or_uri.uri
               elsif opts_or_uri.is_a?(String)
                 begin
                   uri, ref = opts_or_uri.split('#', 2)
                   if PDK::Util::TemplateURI.packaged_template?(uri)
                     PDK::Util::TemplateURI.default_template_addressable_uri.tap { |default| default.fragment = ref unless ref.nil? || ref.empty? }
                   else
                     Addressable::URI.parse(opts_or_uri)
                   end
                 rescue Addressable::URI::InvalidURIError
                   raise PDK::CLI::FatalError, 'PDK::Util::TemplateURI attempted initialization with a non-uri string: {string}' % { string: opts_or_uri }
                 end
               elsif opts_or_uri.is_a?(Addressable::URI)
                 opts_or_uri.dup
               else
                 PDK::Util::TemplateURI.first_valid_uri(PDK::Util::TemplateURI.templates(opts_or_uri))
               end
      end

      def ==(other)
        @uri == other.uri
      end

      def bare_uri
        PDK::Util::TemplateURI.bare_uri(@uri)
      end

      # This is the URI represented in a format suitable for writing to
      # metadata.
      #
      # @returns String
      def metadata_format
        @metadata_format ||= if PDK::Util::TemplateURI.packaged_template?(bare_uri)
                               PDK::Util::TemplateURI.human_readable("pdk-default##{uri_fragment}")
                             else
                               PDK::Util::TemplateURI.human_readable(@uri.to_s)
                             end
      end
      alias to_s metadata_format
      alias to_str metadata_format

      # Returns the fragment of the URI, of the default template's ref if one does not exist
      # @returns String
      # @api private
      def uri_fragment
        @uri.fragment || self.class.default_template_ref(self)
      end

      def uri_fragment=(fragment)
        @uri.fragment = fragment
      end

      def default?
        bare_uri == PDK::Util::TemplateURI.bare_uri(PDK::Util::TemplateURI.default_template_addressable_uri)
      end

      def default_ref?
        uri_fragment == self.class.default_template_ref(self)
      end

      def puppetlabs_template?
        self.class.packaged_template?(bare_uri) || bare_uri == PDK_TEMPLATE_URL
      end

      # Class Methods

      # Remove the fragment off of URI. Useful for removing the branch
      # for Git based URIs
      def self.bare_uri(uri)
        require 'addressable'

        if uri.is_a?(Addressable::URI) && uri.fragment
          human_readable(uri.to_s.chomp('#' + uri.fragment))
        else
          human_readable(uri.to_s)
        end
      end

      # This is the path of the URI, suitable for accessing directly from the shell.
      # @returns String
      def shell_path
        self.class.human_readable(@uri.path)
      end

      # @returns PDK::Util::TemplateURI
      def self.default_template_uri
        require 'pdk/util'
        require 'addressable'

        PDK::Util::TemplateURI.new(default_template_addressable_uri)
      end

      # @returns Addressable::URI
      # @api private
      def self.default_template_addressable_uri
        require 'pdk/util'
        require 'addressable'

        if PDK::Util.package_install?
          Addressable::URI.new(scheme: 'file', host: '', path: File.join(PDK::Util.package_cachedir, 'pdk-templates.git'))
        else
          Addressable::URI.parse(PDK_TEMPLATE_URL)
        end
      end

      # `C:...` urls are not URI-safe. They should be of the form `/C:...` to
      # be URI-safe. scp-like urls like `user@host:/path` are not URI-safe
      # either and so are subsequently converted to ssh:// URIs.
      #
      # @returns String
      def self.uri_safe(string)
        url = (Gem.win_platform? && string =~ %r{^[a-zA-Z][\|:]}) ? "/#{string}" : string
        parse_scp_url(url)
      end

      # If the passed value is a URI-safe windows path such as `/C:...` then it
      # should be changed to a human-friendly `C:...` form. Otherwise the
      # passed value is left alone.
      #
      # @returns String
      def self.human_readable(string)
        (Gem.win_platform? && string =~ %r{^\/[a-zA-Z][\|:]}) ? string[1..-1] : string
      end

      def self.parse_scp_url(url)
        require 'pathname'
        require 'addressable'

        # Valid URIs to avoid catching:
        # - absolute local paths
        # - have :'s in paths when preceeded by a slash
        # - have only digits following the : and preceeding a / or end-of-string that is 0-65535
        # The last item is ambiguous in the case of scp/git paths vs. URI port
        # numbers, but can be made unambiguous by making the form to
        # ssh://git@github.com/1234/repo.git or
        # ssh://git@github.com:1234/user/repo.git
        scp_url = url.match(SCP_PATTERN)
        return url unless Pathname.new(url).relative? && scp_url

        uri = Addressable::URI.new(scheme: 'ssh', user: scp_url[:user], host: scp_url[:host], path: scp_url[:path])
        PDK.logger.warn '%{scp_uri} appears to be an SCP style URL; it will be converted to an RFC compliant URI: %{rfc_uri}' % {
          scp_uri: url,
          rfc_uri: uri.to_s,
        }

        uri.to_s
      end

      # @return [Array<Hash{Symbol => Object}>] an array of hashes. Each hash
      #   contains 3 keys: :type contains a String that describes the template
      #   directory, :url contains a String with the URL to the template
      #   directory, and :allow_fallback contains a Boolean that specifies if
      #   the lookup process should proceed to the next template directory if
      #   the template file is not in this template directory.
      def self.templates(opts)
        require 'pdk/answer_file'
        require 'pdk/util'
        require 'addressable'

        explicit_url = opts.fetch(:'template-url', nil)
        explicit_ref = opts.fetch(:'template-ref', nil)

        # 1. Get the CLI, metadata (or answers if no metadata), and default URIs
        # 2. Construct the hash
        if explicit_url
          explicit_uri = Addressable::URI.parse(uri_safe(explicit_url))
          explicit_uri.fragment = explicit_ref || default_template_ref(new(explicit_uri))
        else
          explicit_uri = nil
        end
        metadata_uri = if PDK::Util.module_root && PDK::Util::Filesystem.file?(File.join(PDK::Util.module_root, 'metadata.json'))
                         if PDK::Util.module_metadata['template-url']
                           new(uri_safe(PDK::Util.module_metadata['template-url'])).uri
                         else
                           nil
                         end
                       else
                         nil
                       end
        default_template_url = PDK.config.get_within_scopes('module_defaults.template-url')
        answers_uri = if [PACKAGED_TEMPLATE_KEYWORD, DEPRECATED_TEMPLATE_URL].include?(default_template_url)
                        Addressable::URI.parse(default_template_uri)
                      elsif default_template_url
                        new(uri_safe(default_template_url)).uri
                      else
                        nil
                      end
        default_uri = default_template_uri.uri
        default_uri.fragment = default_template_ref(default_template_uri)

        ary = []
        ary << { type: '--template-url', uri: explicit_uri, allow_fallback: false } if explicit_url
        ary << { type: 'metadata.json', uri: metadata_uri, allow_fallback: true } if metadata_uri
        ary << { type: 'PDK answers', uri: answers_uri, allow_fallback: true } if answers_uri
        ary << { type: 'default', uri: default_uri, allow_fallback: false }
        ary
      end

      # @returns String
      def self.default_template_ref(uri = nil)
        require 'pdk/util'
        require 'pdk/version'

        return 'main' if PDK::Util.development_mode?
        return PDK::TEMPLATE_REF if uri.nil?

        uri = new(uri) unless uri.is_a?(self)
        uri.default? ? PDK::TEMPLATE_REF : 'main'
      end

      # @returns Addressable::URI
      def self.first_valid_uri(templates_array)
        # 1. Get the four sources of URIs
        # 2. Pick the first non-nil URI
        # 3. Error if the URI is not a valid git repo (missing directory or http 404)
        # 4. Leave updating answers/metadata to other code
        found_template = templates_array.find { |t| valid_template?(t) }

        raise PDK::CLI::FatalError, 'Unable to find a valid module template to use.' if found_template.nil?
        found_template[:uri]
      end

      def self.valid_template?(template, context = PDK.context)
        require 'addressable'

        return false if template.nil? || !template.is_a?(Hash)
        return false if template[:uri].nil? || !template[:uri].is_a?(Addressable::URI)

        return true if PDK::Util::Git.repo?(bare_uri(template[:uri]))
        path = human_readable(template[:uri].path)
        if PDK::Util::Filesystem.directory?(path)
          # We know that it's not a git repository, but it's a valid path on disk
          begin
            renderer = PDK::Template::Renderer.instance(path, template[:uri], context)
            return !renderer.nil?
          rescue StandardError
            nil
          end
        end

        unless template[:allow_fallback]
          raise PDK::CLI::FatalError, 'Unable to find a valid template at %{uri}' % {
            uri: template[:uri].to_s,
          }
        end

        false
      end

      def self.packaged_template?(path)
        path == PACKAGED_TEMPLATE_KEYWORD || LEGACY_PACKAGED_TEMPLATE_PATHS.value?(path)
      end
    end
  end
end
