require 'pdk/util'

module PDK
  module Util
    class TemplateURI
      SCP_PATTERN = %r{\A(?!\w+://)(?:(?<user>.+?)@)?(?<host>[^:/]+):(?<path>.+)\z}

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
                 self.class.first_valid_uri(self.class.templates(opts_or_uri))
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
        self.class.git_remote(@uri)
      end

      def self.git_remote(uri)
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

      # @returns String
      def git_ref
        if @uri.fragment
          @uri.fragment
        else
          self.class.default_template_ref
        end
      end

      def git_ref=(ref)
        @uri.fragment = ref
      end

      # @returns PDK::Util::TemplateURI
      def self.default_template_uri
        if PDK::Util.package_install?
          PDK::Util::TemplateURI.new(Addressable::URI.new(scheme: 'file', host: '', path: File.join(PDK::Util.package_cachedir, 'pdk-templates.git')))
        else
          PDK::Util::TemplateURI.new('https://github.com/puppetlabs/pdk-templates')
        end
      end

      def default?
        git_remote == self.class.default_template_uri.git_remote
      end

      def ref_is_tag?
        PDK::Util::Git.git('ls-remote', '--tags', '--exit-code', git_remote, git_ref)[:exit_code].zero?
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
          scp_url = explicit_url.match(SCP_PATTERN)
          if Pathname.new(uri_safe(explicit_url)).relative? && scp_url
            explicit_uri = Addressable::URI.new(scheme: 'ssh', user: scp_url[:user], host: scp_url[:host], path: scp_url[:path])
            PDK.logger.warn _('%{scp_uri} appears to be an SCP style URL; it will be converted to an RFC compliant URI: %{rfc_uri}') % {
              scp_uri: explicit_url,
              rfc_uri: explicit_uri.to_s,
            }
          end
          explicit_uri ||= Addressable::URI.parse(uri_safe(explicit_url))
          explicit_uri.fragment = explicit_ref || default_template_ref
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
        default_uri.fragment = default_template_ref

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

      # @returns Addressable::URI
      def self.first_valid_uri(templates_array)
        # 1. Get the four sources of URIs
        # 2. Pick the first non-nil URI
        # 3. Error if the URI is not a valid git repo (missing directory or http 404)
        # 4. Leave updating answers/metadata to other code
        found_template = templates_array.find { |t| valid_template?(t) }

        raise PDK::CLI::FatalError, _('Unable to find a valid module template to use.') if found_template.nil?
        found_template[:uri]
      end

      def self.valid_template?(template)
        return false if template.nil? || !template.is_a?(Hash)
        return false if template[:uri].nil? || !template[:uri].is_a?(Addressable::URI)

        return true if PDK::Util::Git.repo?(git_remote(template[:uri]))

        path = human_readable(template[:uri].path)
        if File.directory?(path)
          begin
            PDK::Module::TemplateDir.new(path) {}
            return true
          rescue ArgumentError
            nil
          end
        end

        unless template[:allow_fallback]
          raise PDK::CLI::FatalError, _('Unable to find a valid template at %{uri}') % {
            uri: template[:uri].to_s,
          }
        end

        false
      end
    end
  end
end
