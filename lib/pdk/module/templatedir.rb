require 'pdk'

module PDK
  module Module
    class TemplateDir
      attr_accessor :module_metadata
      attr_reader :uri

      # Initialises the TemplateDir object with the path or URL to the template
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
      #   PDK::Module::TemplateDir.new('https://github.com/puppetlabs/pdk-templates') do |t|
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
      def initialize(uri, module_metadata = {}, init = false)
        require 'pdk/analytics'
        require 'pdk/util/template_uri'
        require 'pdk/util/git'

        unless block_given?
          raise ArgumentError, _('%{class_name} must be initialized with a block.') % { class_name: self.class.name }
        end
        unless uri.is_a? PDK::Util::TemplateURI
          raise ArgumentError, _('PDK::Module::TemplateDir.new must be initialized with a PDK::Util::TemplateURI, got a %{uri_type}') % { uri_type: uri.class }
        end

        if PDK::Util::Git.repo?(uri.git_remote)
          # This is either a bare local repo or a remote. either way it needs cloning.
          @path = clone_template_repo(uri)
          temp_dir_clone = true
        else
          # if it is a local path & non-bare repo then we can use it directly.
          # Still have to check the branch.
          @path = uri.shell_path
          # We don't do a checkout of local-path repos. There are lots of edge
          # cases or user un-expectations.
          if PDK::Util::Git.work_tree?(@path)
            PDK.logger.warn _("Repository '%{repo}' has a work-tree; skipping git reset.") % {
              repo: @path,
            }
          end
        end
        @uri = uri

        @init = init
        @moduleroot_dir = File.join(@path, 'moduleroot')
        @moduleroot_init = File.join(@path, 'moduleroot_init')
        @dirs = [@moduleroot_dir]
        @dirs << @moduleroot_init if @init
        @object_dir = File.join(@path, 'object_templates')

        validate_module_template!

        @module_metadata = module_metadata

        template_type = uri.default? ? 'default' : 'custom'
        PDK.analytics.event('TemplateDir', 'initialize', label: template_type)

        yield self
      ensure
        # If we cloned a git repo to get the template, remove the clone once
        # we're done with it.
        if temp_dir_clone
          require 'fileutils'
          FileUtils.remove_dir(@path)
        end
      end

      # Retrieve identifying metadata for the template.
      #
      # For git repositories, this will return the URL to the repository and
      # a reference to the HEAD.
      #
      # @return [Hash{String => String}] A hash of identifying metadata.
      #
      # @api public
      def metadata
        require 'pdk/util/version'

        {
          'pdk-version'  => PDK::Util::Version.version_string,
          'template-url' => uri.metadata_format,
          'template-ref' => cache_template_ref(@path),
        }
      end

      # Loop through the files in the template, yielding each rendered file to
      # the supplied block.
      #
      # @yieldparam dest_path [String] The path of the destination file,
      # relative to the root of the module.
      # @yieldparam dest_content [String] The rendered content of the
      # destination file.
      #
      # @raise [PDK::CLI::FatalError] If the template fails to render.
      #
      # @return [void]
      #
      # @api public
      def render
        require 'pdk/template_file'

        PDK::Module::TemplateDir.files_in_template(@dirs).each do |template_file, template_loc|
          template_file = template_file.to_s
          PDK.logger.debug(_("Rendering '%{template}'...") % { template: template_file })
          dest_path = template_file.sub(%r{\.erb\Z}, '')
          config = config_for(dest_path)

          dest_status = if template_loc.start_with?(@moduleroot_init)
                          :init
                        else
                          :manage
                        end

          if config['unmanaged']
            dest_status = :unmanage
          elsif config['delete']
            dest_status = :delete
          else
            begin
              dest_content = PDK::TemplateFile.new(File.join(template_loc, template_file), configs: config, template_dir: self).render
            rescue => error
              error_msg = _(
                "Failed to render template '%{template}'\n" \
                '%{exception}: %{message}',
              ) % { template: template_file, exception: error.class, message: error.message }
              raise PDK::CLI::FatalError, error_msg
            end
          end

          yield dest_path, dest_content, dest_status
        end
      end

      # Searches the template directory for template files that can be used to
      # render files for the specified object type.
      #
      # @param object_type [Symbol] The object type, e.g. (`:class`,
      # `:defined_type`, `:fact`, etc).
      #
      # @return [Hash{Symbol => String}] if the templates are available in the
      # template dir, otherwise `nil`. The returned hash can contain two keys,
      # :object contains the path on disk to the template for the object, :spec
      # contains the path on disk to the template for the object's spec file
      # (if available).
      #
      # @api public
      def object_template_for(object_type)
        object_path = File.join(@object_dir, "#{object_type}.erb")
        type_path = File.join(@object_dir, "#{object_type}_type.erb")
        device_path = File.join(@object_dir, "#{object_type}_device.erb")
        spec_path = File.join(@object_dir, "#{object_type}_spec.erb")
        type_spec_path = File.join(@object_dir, "#{object_type}_type_spec.erb")

        if PDK::Util::Filesystem.file?(object_path) && File.readable?(object_path)
          result = { object: object_path }
          result[:type] = type_path if PDK::Util::Filesystem.file?(type_path) && File.readable?(type_path)
          result[:spec] = spec_path if PDK::Util::Filesystem.file?(spec_path) && File.readable?(spec_path)
          result[:device] = device_path if PDK::Util::Filesystem.file?(device_path) && File.readable?(device_path)
          result[:type_spec] = type_spec_path if PDK::Util::Filesystem.file?(type_spec_path) && File.readable?(type_spec_path)
          result
        else
          nil
        end
      end

      # Generate a hash of data to be used when rendering object templates.
      #
      # Read `config_defaults.yml` from the root of the template directory (if
      # it exists) build a hash of values from the value of the `:global`
      # key.
      #
      # @return [Hash] The data that will be available to the template via the
      # `@configs` instance variable.
      #
      # @api private
      def object_config
        config_for(nil)
      end

      # Validate the content of the template directory.
      #
      # @raise [ArgumentError] If the specified path is not a directory.
      # @raise [ArgumentError] If the template directory does not contain
      # a directory called 'moduleroot'.
      #
      # @return [void]
      #
      # @api private
      def validate_module_template!
        # rubocop:disable Style/GuardClause
        unless PDK::Util::Filesystem.directory?(@path)
          require 'pdk/util'

          if PDK::Util.package_install? && PDK::Util::Filesystem.fnmatch?(File.join(PDK::Util.package_cachedir, '*'), @path)
            raise ArgumentError, _('The built-in template has substantially changed. Please run "pdk convert" on your module to continue.')
          else
            raise ArgumentError, _("The specified template '%{path}' is not a directory.") % { path: @path }
          end
        end

        unless PDK::Util::Filesystem.directory?(@moduleroot_dir)
          raise ArgumentError, _("The template at '%{path}' does not contain a 'moduleroot/' directory.") % { path: @path }
        end

        unless PDK::Util::Filesystem.directory?(@moduleroot_init)
          # rubocop:disable Metrics/LineLength
          raise ArgumentError, _("The template at '%{path}' does not contain a 'moduleroot_init/' directory, which indicates you are using an older style of template. Before continuing please use the --template-url flag when running the pdk new commands to pass a new style template.") % { path: @path }
          # rubocop:enable Metrics/LineLength Style/GuardClause
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
          raise ArgumentError, _("The directory '%{dir}' doesn't exist") % { dir: dir } unless Dir.exist?(dir)
          temp_paths += PDK::Util::Filesystem.glob(File.join(dir, '**', '*'), File::FNM_DOTMATCH).select do |template_path|
            if PDK::Util::Filesystem.file?(template_path) && !File.symlink?(template_path)
              dirlocs << dir
            end
          end
          temp_paths.map do |template_path|
            template_path.sub!(%r{\A#{Regexp.escape(dir)}#{Regexp.escape(File::SEPARATOR)}}, '')
          end
        end
        Hash[temp_paths.zip dirlocs]
      end

      # Generate a hash of data to be used when rendering the specified
      # template.
      #
      # @param dest_path [String] The destination path of the file that the
      # data is for, relative to the root of the module.
      #
      # @return [Hash] The data that will be available to the template via the
      # `@configs` instance variable.
      #
      # @api private
      def config_for(dest_path, sync_config_path = nil)
        require 'pdk/util'
        require 'pdk/analytics'

        module_root = PDK::Util.module_root
        sync_config_path ||= File.join(module_root, '.sync.yml') unless module_root.nil?
        config_path = File.join(@path, 'config_defaults.yml')

        if @config.nil?
          require 'deep_merge'
          conf_defaults = read_config(config_path)
          @sync_config = read_config(sync_config_path) unless sync_config_path.nil?
          @config = conf_defaults
          @config.deep_merge!(@sync_config, knockout_prefix: '---') unless @sync_config.nil?
        end
        file_config = @config.fetch(:global, {})
        file_config['module_metadata'] = @module_metadata
        file_config.merge!(@config.fetch(dest_path, {})) unless dest_path.nil?
        file_config.merge!(@config).tap do |c|
          if uri.default?
            file_value = if c['unmanaged']
                           'unmanaged'
                         elsif c['delete']
                           'deleted'
                         elsif @sync_config && @sync_config.key?(dest_path)
                           'customized'
                         else
                           'default'
                         end

            PDK.analytics.event('TemplateDir', 'file', label: dest_path, value: file_value)
          end
        end
      end

      # Generates a hash of data from a given yaml file location.
      #
      # @param loc [String] The path of the yaml config file.
      #
      # @warn If the specified path is not a valid yaml file. Returns an empty Hash
      # if so.
      #
      # @return [Hash] The data that has been read in from the given yaml file.
      #
      # @api private
      def read_config(loc)
        if PDK::Util::Filesystem.file?(loc) && File.readable?(loc)
          require 'yaml'

          begin
            YAML.safe_load(File.read(loc), [], [], true)
          rescue Psych::SyntaxError => e
            PDK.logger.warn _("'%{file}' is not a valid YAML file: %{problem} %{context} at line %{line} column %{column}") % {
              file:    loc,
              problem: e.problem,
              context: e.context,
              line:    e.line,
              column:  e.column,
            }
            {}
          end
        else
          {}
        end
      end

      # @return [String] Path to working directory into which template repo has been cloned and reset
      #
      # @raise [PDK::CLI::FatalError] If unable to clone the given origin_repo into a tempdir.
      # @raise [PDK::CLI::FatalError] If reset HEAD of the cloned repo to desired ref.
      #
      # @api private
      def clone_template_repo(uri)
        # @todo When switching this over to using rugged, cache the cloned
        # template repo in `%AppData%` or `$XDG_CACHE_DIR` and update before
        # use.
        require 'pdk/util'
        require 'pdk/util/git'

        temp_dir = PDK::Util.make_tmpdir_name('pdk-templates')
        origin_repo = uri.git_remote
        git_ref = uri.git_ref

        clone_result = PDK::Util::Git.git('clone', origin_repo, temp_dir)

        if clone_result[:exit_code].zero?
          checkout_template_ref(temp_dir, git_ref)
        else
          PDK.logger.error clone_result[:stdout]
          PDK.logger.error clone_result[:stderr]
          raise PDK::CLI::FatalError, _("Unable to clone git repository at '%{repo}' into '%{dest}'.") % { repo: origin_repo, dest: temp_dir }
        end

        PDK::Util.canonical_path(temp_dir)
      end

      # @api private
      def checkout_template_ref(path, ref)
        require 'pdk/util/git'

        if PDK::Util::Git.work_dir_clean?(path)
          Dir.chdir(path) do
            full_ref = PDK::Util::Git.ls_remote(path, ref)
            cache_template_ref(path, full_ref)
            reset_result = PDK::Util::Git.git('reset', '--hard', full_ref)
            return if reset_result[:exit_code].zero?

            PDK.logger.error reset_result[:stdout]
            PDK.logger.error reset_result[:stderr]
            raise PDK::CLI::FatalError, _("Unable to checkout '%{ref}' of git repository at '%{path}'.") % { ref: ref, path: path }
          end
        else
          PDK.logger.warn _("Uncommitted changes found when attempting to checkout '%{ref}' of git repository at '%{path}'; skipping git reset.") % { ref: ref, path: path }
        end
      end

      def cache_template_ref(path, ref = nil)
        require 'pdk/util/git'

        @template_ref ||= PDK::Util::Git.describe(File.join(path, '.git'), ref)
      end
    end
  end
end
