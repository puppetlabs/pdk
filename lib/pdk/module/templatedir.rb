require 'yaml'
require 'pdk/util'
require 'pdk/cli/exec'
require 'pdk/cli/errors'
require 'pdk/template_file'

module PDK
  module Module
    class TemplateDir
      # Initialises the TemplateDir object with the path or URL to the template
      # and the block of code to run to be run while the template is available.
      #
      # The template directory is only guaranteed to be available on disk
      # within the scope of the block passed to this method.
      #
      # @param path_or_url [String] The path to a directory to use as the
      # template or a URL to a git repository.
      # @yieldparam self [PDK::Module::TemplateDir] The initialised object with
      # the template available on disk.
      #
      # @example Using a git repository as a template
      #   PDK::Module::TemplateDir.new('https://github.com/puppetlabs/pdk-module-template') do |t|
      #     t.render do |filename, content|
      #       File.open(filename, 'w') do |file|
      #         file.write(content)
      #       end
      #     end
      #   end
      #
      # @raise [PDK::CLI::FatalError] If the template is a git repository and
      # the git binary is unavailable.
      # @raise [PDK::CLI::FatalError] If the template is a git repository and
      # the git clone operation fails.
      # @raise [ArgumentError] (see #validate_module_template!)
      #
      # @api public
      def initialize(path_or_url)
        if File.directory?(path_or_url)
          @path = path_or_url
        else
          # If path_or_url isn't a directory on disk, we assume that it is
          # a remote git repository.

          # @todo When switching this over to using rugged, cache the cloned
          # template repo in `%AppData%` or `$XDG_CACHE_DIR` and update before
          # use.
          temp_dir = PDK::Util.make_tmpdir_name('pdk-module-template')

          clone_result = PDK::CLI::Exec.git('clone', path_or_url, temp_dir)
          unless clone_result[:exit_code].zero?
            PDK.logger.error clone_result[:stdout]
            PDK.logger.error clone_result[:stderr]
            raise PDK::CLI::FatalError, _("Unable to clone git repository '%{repo}' to '%{dest}'") % { repo: path_or_url, dest: temp_dir }
          end

          @path = PDK::Util.canonical_path(temp_dir)
          @repo = path_or_url
        end

        @moduleroot_dir = File.join(@path, 'moduleroot')
        @object_dir = File.join(@path, 'object_templates')
        validate_module_template!

        yield self
      ensure
        # If we cloned a git repo to get the template, remove the clone once
        # we're done with it.
        if @repo
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
        return {} unless @repo

        ref_result = PDK::CLI::Exec.git('--git-dir', File.join(@path, '.git'), 'describe', '--all', '--long')
        if ref_result[:exit_code].zero?
          { 'template-url' => @repo, 'template-ref' => ref_result[:stdout].strip }
        else
          {}
        end
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
        files_in_template.each do |template_file|
          PDK.logger.debug(_("Rendering '%{template}'...") % { template: template_file })
          dest_path = template_file.sub(%r{\.erb\Z}, '')

          begin
            dest_content = PDK::TemplateFile.new(File.join(@moduleroot_dir, template_file), configs: config_for(dest_path)).render
          rescue => e
            error_msg = _(
              "Failed to render template '%{template}'\n" \
              '%{exception}: %{message}',
            ) % { template: template_file, exception: e.class, message: e.message }
            raise PDK::CLI::FatalError, error_msg
          end

          yield dest_path, dest_content
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
        spec_path = File.join(@object_dir, "#{object_type}_spec.erb")

        if File.file?(object_path) && File.readable?(object_path)
          result = { object: object_path }
          result[:spec] = spec_path if File.file?(spec_path) && File.readable?(spec_path)
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

      private

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
        unless File.directory?(@path)
          raise ArgumentError, _("The specified template '%{path}' is not a directory") % { path: @path }
        end

        unless File.directory?(@moduleroot_dir) # rubocop:disable Style/GuardClause
          raise ArgumentError, _("The template at '%{path}' does not contain a 'moduleroot/' directory") % { path: @path }
        end
      end

      # Get a list of template files in the template directory.
      #
      # @return [Array[String]] An array of file names, relative to the
      # `moduleroot` directory.
      #
      # @api private
      def files_in_template
        @files ||= begin
          template_paths = Dir.glob(File.join(@moduleroot_dir, '**', '*'), File::FNM_DOTMATCH).select do |template_path|
            File.file?(template_path) && !File.symlink?(template_path)
          end

          template_paths.map do |template_path|
            template_path.sub(%r{\A#{Regexp.escape(@moduleroot_dir)}#{Regexp.escape(File::SEPARATOR)}}, '')
          end
        end
      end

      # Generate a hash of data to be used when rendering the specified
      # template.
      #
      # Read `config_defaults.yml` from the root of the template directory (if
      # it exists) build a hash of values by merging the value of the `:global`
      # key with the value of the key that matches `dest_path`.
      #
      # @param dest_path [String] The destination path of the file that the
      # data is for, relative to the root of the module.
      #
      # @return [Hash] The data that will be available to the template via the
      # `@configs` instance variable.
      #
      # @api private
      def config_for(dest_path)
        if @config.nil?
          config_path = File.join(@path, 'config_defaults.yml')

          if File.file?(config_path) && File.readable?(config_path)
            begin
              @config = YAML.safe_load(File.read(config_path), [], [], true)
            rescue StandardError => e
              PDK.logger.warn(_("'%{file}' is not a valid YAML file: %{message}") % { file: config_path, message: e.message })
              @config = {}
            end
          else
            @config = {}
          end
        end

        file_config = @config.fetch(:global, {})
        file_config.merge(@config.fetch(dest_path, {})) unless dest_path.nil?
      end
    end
  end
end
