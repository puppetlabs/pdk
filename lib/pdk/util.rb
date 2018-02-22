require 'tmpdir'
require 'tempfile'

require 'pdk/util/version'
require 'pdk/util/windows'
require 'pdk/util/vendored_file'
require 'pdk/util/filesystem'

module PDK
  module Util
    MODULE_FOLDERS = %w[
      manifests
      lib
      tasks
      facts.d
      functions
      types
    ].freeze

    # Searches upwards from current working directory for the given target file.
    #
    # @param target [String] Name of file to search for.
    # @param start_dir [String] Directory to start searching from, defaults to Dir.pwd
    #
    # @return [String, nil] Fully qualified path to the given target file if found,
    #   nil if the target file could not be found.
    def find_upwards(target, start_dir = nil)
      previous = nil
      current  = File.expand_path(start_dir || Dir.pwd)

      until !File.directory?(current) || current == previous
        filename = File.join(current, target)
        return filename if File.file?(filename)
        previous = current
        current = File.expand_path('..', current)
      end
    end
    module_function :find_upwards

    # Generate a name for a temporary directory.
    #
    # @param base [String] A string to base the name generation off.
    #
    # @return [String] The temporary directory path.
    def make_tmpdir_name(base)
      t = Time.now.strftime('%Y%m%d')
      name = "#{base}#{t}-#{Process.pid}-#{rand(0x100000000).to_s(36)}"
      File.join(Dir.tmpdir, name)
    end
    module_function :make_tmpdir_name

    # Return an expanded, absolute path
    #
    # @param path [String] Existing path that may not be canonical
    #
    # @return [String] Canonical path
    def canonical_path(path)
      if Gem.win_platform?
        unless File.exist?(path)
          raise PDK::CLI::FatalError, _("Cannot resolve a full path to '%{path}', as it does not currently exist.") % { path: path }
        end
        PDK::Util::Windows::File.get_long_pathname(path)
      else
        File.expand_path(path)
      end
    end
    module_function :canonical_path

    def package_install?
      !PDK::Util::Version.version_file.nil?
    end
    module_function :package_install?

    def development_mode?
      (!PDK::Util::Version.git_ref.nil? || PDK::VERSION.end_with?('.pre'))
    end
    module_function :development_mode?

    def gem_install?
      !(package_install? || development_mode?)
    end
    module_function :gem_install?

    def pdk_package_basedir
      raise PDK::CLI::FatalError, _('Package basedir requested for non-package install.') unless package_install?

      File.dirname(PDK::Util::Version.version_file)
    end
    module_function :pdk_package_basedir

    def package_cachedir
      File.join(pdk_package_basedir, 'share', 'cache')
    end
    module_function :package_cachedir

    # Returns the fully qualified path to a per-user PDK cachedir.
    #
    # @return [String] Fully qualified path to per-user PDK cachedir.
    def cachedir
      if Gem.win_platform?
        File.join(ENV['LOCALAPPDATA'], 'PDK', 'cache')
      else
        File.join(Dir.home, '.pdk', 'cache')
      end
    end
    module_function :cachedir

    # Returns path to the root of the module being worked on.
    #
    # @return [String, nil] Fully qualified base path to module, or nil if
    #   the current working dir does not appear to be within a module.
    def module_root
      metadata_path = find_upwards('metadata.json')
      if metadata_path
        File.dirname(metadata_path)
      elsif in_module_root?
        Dir.pwd
      else
        nil
      end
    end
    module_function :module_root

    # Returns true or false depending on if any of the common directories in a module
    # are found in the current directory
    #
    # @return [boolean] True if any folders from MODULE_FOLDERS are found in the current dir,
    #   false otherwise.
    def in_module_root?
      PDK::Util::MODULE_FOLDERS.any? { |dir| File.directory?(dir) }
    end
    module_function :in_module_root?

    # Iterate through possible JSON documents until we find one that is valid.
    #
    # @param [String] text the text in which to find a JSON document
    # @return [Hash, nil] subset of text as Hash of first valid JSON found, or nil if no valid
    #   JSON found in the text
    def find_first_json_in(text)
      find_valid_json_in(text)
    end
    module_function :find_first_json_in

    # Iterate through possible JSON documents for all valid JSON
    #
    # @param [String] text the text in which to find JSON document(s)
    # @return [Array<Hash>] subset of text as Array of all JSON object found, empty Array if none are found
    #   JSON found in the text
    def find_all_json_in(text)
      find_valid_json_in(text, break_on_first: false)
    end
    module_function :find_all_json_in

    # Iterate through possible JSON documents until we find one that is valid.
    #
    # @param [String] text the text in which to find a JSON document
    # @param [Hash] opts options
    # @option opts [Boolean] :break_on_first Whether or not to break after valid JSON is found, defaults to true
    #
    # @return [Hash, Array<Hash>, nil] subset of text as Hash of first valid JSON found, array of all valid JSON found, or nil if no valid
    #   JSON found in the text
    #
    # @private
    def find_valid_json_in(text, opts = {})
      break_on_first = opts.key?(:break_on_first) ? opts[:break_on_first] : true

      json_result = break_on_first ? nil : []

      text.scan(%r{\{(?:[^{}]|(?:\g<0>))*\}}x) do |str|
        begin
          if break_on_first
            json_result = JSON.parse(str)
            break
          else
            json_result.push(JSON.parse(str))
          end
        rescue JSON::ParserError
          next
        end
      end

      json_result
    end
    module_function :find_valid_json_in

    # Returns the targets' paths relative to the working directory
    #
    # @return [Array<String>] The absolute or path to the target
    def targets_relative_to_pwd(targets)
      targets.map do |t|
        if Pathname.new(t).absolute?
          Pathname.new(t).relative_path_from(Pathname.pwd)
        else
          t
        end
      end
    end
    module_function :targets_relative_to_pwd

    # @returns String
    def template_url(uri)
      if uri.is_a?(Addressable::URI) && uri.fragment
        deuri_path(uri.to_s.chomp('#' + uri.fragment))
      else
        deuri_path(uri.to_s)
      end
    end
    module_function :template_url
    # @returns String
    def template_ref(uri)
      if uri.fragment
        uri.fragment
      else
        default_template_ref
      end
    end
    module_function :template_ref
    # @returns String
    def template_path(uri)
      deuri_path(uri.path)
    end
    module_function :template_path
    # C:\... urls are not URI-safe. They should be /C:\... to be so.
    # @returns String
    def uri_path(path)
      (Gem.win_platform? && path =~ %r{^[a-zA-Z][\|:]}) ? "/#{path}" : path
    end
    module_function :uri_path
    # @returns String
    def deuri_path(path)
      (Gem.win_platform? && path =~ %r{^\/[a-zA-Z][\|:]}) ? path[1..-1] : path
    end
    module_function :deuri_path

    # @returns Addressable::URI
    def template_uri(opts)
      # 1. Get the four sources of URIs
      # 2. Pick the first non-nil URI
      # 3. Error if the URI is not a valid git repo (missing directory or http 404)
      # 4. Leave updating answers/metadata to other code
      # XXX Make it work before making it pretty.
      found_template = templates(opts).find { |t| valid_template?(t) }

      raise PDK::CLI::FatalError, _('Unable to find a valid module template to use.') if found_template.nil?
      found_template[:uri]
    end
    module_function :template_uri

    def valid_template?(template)
      return false if template.nil?
      return false if template[:uri].nil?

      if template[:path] && File.directory?(template[:path])
        PDK::Module::TemplateDir.new(template[:uri]) {}
        return true
      end
      return true if PDK::Util::Git.repo?(template[:uri])

      false
    rescue ArgumentError
      return false
    end
    module_function :valid_template?

    # @return [Array<Hash{Symbol => Object}>] an array of hashes. Each hash
    #   contains 3 keys: :type contains a String that describes the template
    #   directory, :url contains a String with the URL to the template
    #   directory, and :allow_fallback contains a Boolean that specifies if
    #   the lookup process should proceed to the next template directory if
    #   the template file is not in this template directory.
    #
    def templates(opts)
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
        explicit_uri = Addressable::URI.parse(uri_path(explicit_url))
        explicit_uri.fragment = explicit_ref
      else
        explicit_uri = nil
      end
      metadata_uri = if module_root && File.file?(File.join(module_root, 'metadata.json'))
                       Addressable::URI.parse(uri_path(module_metadata['template-url']))
                     else
                       nil
                     end
      answers_uri = if PDK.answers['template-url'] == 'https://github.com/puppetlabs/pdk-module-template'
                      # use the new github template-url if it is still the old one.
                      default_template_uri
                    elsif PDK.answers['template-url']
                      Addressable::URI.parse(uri_path(PDK.answers['template-url']))
                    else
                      nil
                    end
      default_uri = default_template_uri

      ary = []
      ary << { type: _('--template-url'), uri: explicit_uri, allow_fallback: false }
      ary << { type: _('metadata.json'), uri: metadata_uri, allow_fallback: true } if metadata_uri
      ary << { type: _('PDK answers'), uri: answers_uri, allow_fallback: true } unless metadata_uri
      ary << { type: _('default'), uri: default_uri, allow_fallback: false }
      ary
    end
    module_function :templates

    # @returns Addressable::URI
    def default_template_uri
      if package_install?
        Addressable::URI.new(scheme: 'file', host: '', path: File.join(package_cachedir, 'pdk-templates.git'))
      else
        Addressable::URI.parse('https://github.com/puppetlabs/pdk-templates')
      end
    end
    module_function :default_template_uri

    # @returns String
    def default_template_ref
      if PDK::Util.development_mode?
        'master'
      else
        PDK::TEMPLATE_REF
      end
    end
    module_function :default_template_ref

    # TO-DO: Refactor replacement of lib/pdk/module/build.rb:metadata to use this function instead
    def module_metadata
      PDK::Module::Metadata.from_file(File.join(module_root, 'metadata.json')).data
    end
    module_function :module_metadata

    # TO-DO: Refactor replacement of lib/pdk/module/build.rb:module_pdk_compatible? to use this function instead
    def module_pdk_compatible?
      ['pdk-version', 'template-url'].any? { |key| module_metadata.key?(key) }
    end
    module_function :module_pdk_compatible?

    def module_pdk_version
      metadata = module_metadata

      if metadata.nil? || metadata.fetch('pdk-version', nil).nil?
        nil
      else
        metadata['pdk-version'].split.first
      end
    rescue ArgumentError => e
      PDK.logger.error(e)
      nil
    end
    module_function :module_pdk_version
  end
end
