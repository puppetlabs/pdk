require 'pdk/util'

module PDK
  module Util
    class TemplateURI
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
      # file:///c:/foo#master (only for metadata)
      # c:/foo#master (only for metadata)
      #
      # non output formats:
      #
      # /c:/foo (internal use only)
      # /c:/foo#master (internal use only)
      #
      def initialize(opts_or_uri)
        # If a uri string is passed, skip the valid uri finding code.
        @uri = if opts_or_uri.is_a?(String) || opts_or_uri.is_a?(self.class)
                 begin
                   Addressable::URI.parse(opts_or_uri)
                 rescue Addressable::URI::InvalidURIError
                   raise PDK::CLI::FatalError, _('PDK::Util::TemplateURI attempted initialization with a non-uri string: {string}') % { string: opts_or_uri }
                 end
               elsif opts_or_uri.is_a?(Addressable::URI)
                 opts_or_uri.dup
               else
                 first_valid_uri(self.class.templates(opts_or_uri))
               end
      end

      def ==(other)
        @uri == other.uri
      end

      # This is the URI represented in a format suitable for writing to
      # metadata.
      #
      # @returns String
      def metadata_format
        self.class.human_readable(@uri.to_s)
      end
      alias to_s metadata_format
      alias to_str metadata_format

      # This is the url without a fragment, suitable for git clones.
      #
      # @returns String
      def git_remote
        if @uri.is_a?(Addressable::URI) && @uri.fragment
          self.class.human_readable(@uri.to_s.chomp('#' + @uri.fragment))
        else
          self.class.human_readable(@uri.to_s)
        end
      end

      # This is the path of the URI, suitable for accessing directly from the shell.
      # @returns String
      def shell_path
        self.class.human_readable(@uri.path)
      end

      # @returns String
      def git_ref
        if @uri.fragment
          @uri.fragment
        else
          self.class.default_template_ref
        end
      end

      # @returns PDK::Util::TemplateURI
      def self.default_template_uri
        if PDK::Util.package_install?
          PDK::Util::TemplateURI.new(Addressable::URI.new(scheme: 'file', host: '', path: File.join(PDK::Util.package_cachedir, 'pdk-templates.git')))
        else
          PDK::Util::TemplateURI.new('https://github.com/puppetlabs/pdk-templates')
        end
      end

      # `C:...` urls are not URI-safe. They should be of the form `/C:...` to
      # be URI-safe. scp-like urls like `user@host:/path` are not URI-safe
      # either but are not handled here. Should they be?
      #
      # @returns String
      def self.uri_safe(string)
        (Gem.win_platform? && string =~ %r{^[a-zA-Z][\|:]}) ? "/#{string}" : string
      end

      # If the passed value is a URI-safe windows path such as `/C:...` then it
      # should be changed to a human-friendly `C:...` form. Otherwise the
      # passed value is left alone.
      #
      # @returns String
      def self.human_readable(string)
        (Gem.win_platform? && string =~ %r{^\/[a-zA-Z][\|:]}) ? string[1..-1] : string
      end

      # @return [Array<Hash{Symbol => Object}>] an array of hashes. Each hash
      #   contains 3 keys: :type contains a String that describes the template
      #   directory, :url contains a String with the URL to the template
      #   directory, and :allow_fallback contains a Boolean that specifies if
      #   the lookup process should proceed to the next template directory if
      #   the template file is not in this template directory.
      #
      def self.templates(opts)
        explicit_url = opts.fetch(:'template-url', nil)
        explicit_ref = opts.fetch(:'template-ref', nil)

        if explicit_ref && explicit_url.nil?
          raise PDK::CLI::FatalError, _('--template-ref requires --template-url to also be specified.')
        end
        if explicit_url && explicit_url.include?('#')
          raise PDK::CLI::FatalError, _('--template-url may not be used to specify paths containing #\'s')
        end

        # 1. Get the CLI, metadata (or answers if no metadata), and default URIs
        # 2. Construct the hash
        if explicit_url
          # Valid URIs to avoid catching:
          # - absolute local paths
          # - have :'s in paths when preceeded by a slash
          # - have only digits following the : and preceeding a / or end-of-string that is 0-65535
          # The last item is ambiguous in the case of scp/git paths vs. URI port
          # numbers, but can be made unambiguous by making the form to
          # ssh://git@github.com/1234/repo.git or
          # ssh://git@github.com:1234/user/repo.git
          scp_url_m = explicit_url.match(%r{\A(.*@[^/:]+):(.+)\z})
          if Pathname.new(explicit_url).relative? && scp_url_m
            # "^git@..." is also malformed as it is missing a scheme
            # "ssh://git@..." is correct.
            check_url = Addressable::URI.parse(scp_url_m[1])
            scheme = 'ssh://' unless check_url.scheme

            numbers_m = scp_url_m[2].split('/')[0].match(%r{\A[0-9]+\z})
            if numbers_m && numbers_m[0].to_i < 65_536
              # consider it an explicit-port URI, even though it's ambiguous.
              explicit_url = Addressable::URI.parse(scheme + scp_url_m[1] + ':' + scp_url_m[2])
            else
              explicit_url = Addressable::URI.parse(scheme + scp_url_m[1] + '/' + scp_url_m[2])
              PDK.logger.warn(_('--template-url appears to be an SCP-style url; it will be converted to an RFC-compliant URI: %{uri}') % { uri: explicit_url })
            end
          end
          explicit_uri = Addressable::URI.parse(uri_safe(explicit_url))
          explicit_uri.fragment = explicit_ref
        else
          explicit_uri = nil
        end
        metadata_uri = if PDK::Util.module_root && File.file?(File.join(PDK::Util.module_root, 'metadata.json'))
                         Addressable::URI.parse(uri_safe(PDK::Util.module_metadata['template-url']))
                       else
                         nil
                       end
        answers_uri = if PDK.answers['template-url'] == 'https://github.com/puppetlabs/pdk-module-template'
                        # use the new github template-url if it is still the old one.
                        Addressable::URI.parse(default_template_uri)
                      elsif PDK.answers['template-url']
                        Addressable::URI.parse(uri_safe(PDK.answers['template-url']))
                      else
                        nil
                      end
        default_uri = Addressable::URI.parse(default_template_uri)

        ary = []
        ary << { type: _('--template-url'), uri: explicit_uri, allow_fallback: false }
        ary << { type: _('metadata.json'), uri: metadata_uri, allow_fallback: true } if metadata_uri
        ary << { type: _('PDK answers'), uri: answers_uri, allow_fallback: true } if answers_uri
        ary << { type: _('default'), uri: default_uri, allow_fallback: false }
        ary
      end

      # @returns String
      def self.default_template_ref
        if PDK::Util.development_mode?
          'master'
        else
          PDK::TEMPLATE_REF
        end
      end

      private

      # @returns Addressable::URI
      def first_valid_uri(templates_array)
        # 1. Get the four sources of URIs
        # 2. Pick the first non-nil URI
        # 3. Error if the URI is not a valid git repo (missing directory or http 404)
        # 4. Leave updating answers/metadata to other code
        found_template = templates_array.find { |t| valid_template?(t) }

        raise PDK::CLI::FatalError, _('Unable to find a valid module template to use.') if found_template.nil?
        found_template[:uri]
      end

      def valid_template?(template)
        return false if template.nil?
        return false if template[:uri].nil?

        if template[:path] && File.directory?(template[:path])
          PDK::Module::TemplateDir.new(template[:uri]) {}
          return true
        end
        repo = if template[:uri].fragment
                 template[:uri].to_s.chomp("##{template[:uri].fragment}")
               else
                 template[:uri].to_s
               end
        return true if PDK::Util::Git.repo?(repo)

        false
      rescue ArgumentError
        return false
      end
    end
  end
end
