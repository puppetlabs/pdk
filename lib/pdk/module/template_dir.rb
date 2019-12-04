require 'pdk'

module PDK
  module Module
    module TemplateDir
      # Creates a TemplateDir object with the path or URL to the template
      # and the block of code to run to be run while the template is available.
      #
      # The template directory is only guaranteed to be available on disk
      # within the scope of the block passed to this method.
      #
      # @param uri [PDK::Util::TemplateURI] The path to a directory to use as the
      # template or a URI to a git repository.
      # @param module_metadata [Hash] A Hash containing the module metadata.
      # Defaults to an empty Hash.
      # @yieldparam self [PDK::Module::TemplateDir] The initialised object with
      # the template available on disk.
      #
      # @example Using a git repository as a template
      #   PDK::Module::TemplateDir.with('https://github.com/puppetlabs/pdk-templates') do |t|
      #     t.render do |filename, content|
      #       File.open(filename, 'w') do |file|
      #         file.write(content)
      #       end
      #     end
      #   end
      #
      # @raise [ArgumentError] If no block is given to this method.
      # @raise [PDK::CLI::FatalError] (see #clone_repo)
      # @raise [ArgumentError] (see #validate_module_template!)
      #
      # @api public
      def self.with(uri, module_metadata = {}, init = false)
        unless block_given?
          raise ArgumentError, _('%{class_name}.with must be passed a block.') % { class_name: name }
        end
        unless uri.is_a? PDK::Util::TemplateURI
          raise ArgumentError, _('%{class_name}.with must be passed a PDK::Util::TemplateURI, got a %{uri_type}') % { uri_type: uri.class, class_name: name }
        end

        if PDK::Util::Git.repo?(uri.bare_uri)
          require 'pdk/module/template_dir/git'
          PDK::Module::TemplateDir::Git.new(uri, module_metadata, init) { |value| yield value }
        else
          require 'pdk/module/template_dir/local'
          PDK::Module::TemplateDir::Local.new(uri, module_metadata, init) { |value| yield value }
        end
      end

      def self.moduleroot_dir(template_root_dir)
        File.join(template_root_dir, 'moduleroot')
      end

      def self.moduleroot_init(template_root_dir)
        File.join(template_root_dir, 'moduleroot_init')
      end

      # Validate the content of the template directory.
      #
      # @raise [ArgumentError] If the specified path is not a directory.
      # @raise [ArgumentError] If the template directory does not contain
      # a directory called 'moduleroot'.
      #
      # @return [void]
      #
      # @api public
      def self.validate_module_template!(template_root_dir)
        # rubocop:disable Style/GuardClause
        unless PDK::Util::Filesystem.directory?(template_root_dir)
          require 'pdk/util'

          if PDK::Util.package_install? && PDK::Util::Filesystem.fnmatch?(File.join(PDK::Util.package_cachedir, '*'), template_root_dir)
            raise ArgumentError, _('The built-in template has substantially changed. Please run "pdk convert" on your module to continue.')
          else
            raise ArgumentError, _("The specified template '%{path}' is not a directory.") % { path: template_root_dir }
          end
        end

        unless PDK::Util::Filesystem.directory?(moduleroot_dir(template_root_dir))
          raise ArgumentError, _("The template at '%{path}' does not contain a 'moduleroot/' directory.") % { path: template_root_dir }
        end

        unless PDK::Util::Filesystem.directory?(moduleroot_init(template_root_dir))
          # rubocop:disable Metrics/LineLength
          raise ArgumentError, _("The template at '%{path}' does not contain a 'moduleroot_init/' directory, which indicates you are using an older style of template. Before continuing please use the --template-url flag when running the pdk new commands to pass a new style template.") % { path: template_root_dir }
          # rubocop:enable Metrics/LineLength
        end
        # rubocop:enable Style/GuardClause
      end

      # Get a list of template files in the template directory.
      #
      # @return [Hash{String=>String}] A hash of key file names and
      # value locations.
      #
      # @api public
      def self.files_in_template(dirs)
        temp_paths = []
        dirlocs = []
        dirs.each do |dir|
          raise ArgumentError, _("The directory '%{dir}' doesn't exist") % { dir: dir } unless PDK::Util::Filesystem.directory?(dir)
          temp_paths += PDK::Util::Filesystem.glob(File.join(dir, '**', '*'), File::FNM_DOTMATCH).select do |template_path|
            if PDK::Util::Filesystem.file?(template_path) && !PDK::Util::Filesystem.symlink?(template_path)
              dirlocs << dir
            end
          end
          temp_paths.map do |template_path|
            template_path.sub!(%r{\A#{Regexp.escape(dir)}#{Regexp.escape(File::SEPARATOR)}}, '')
          end
        end
        Hash[temp_paths.zip dirlocs]
      end
    end
  end
end
