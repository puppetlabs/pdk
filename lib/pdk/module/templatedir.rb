require 'erb'
require 'ostruct'
require 'yaml'
require 'pdk/util'
require 'pdk/cli/exec'
require 'pdk/cli/errors'

module PDK
  module Module
    class TemplateDir
      def initialize(path_or_url)
        @path_or_url = path_or_url
      end

      def with_templates(&block)
        if File.directory?(@path_or_url)
          @path = @path_or_url
        else
          # If path_or_url isn't a directory on disk, we assume that it is
          # a remote git repository.

          # TODO: When switching this over to using rugged, cache the cloned
          # template repo in `%AppData%` or `$XDG_CACHE_DIR` and update before
          # use.
          temp_dir = PDK::Util.make_tmpdir_name('pdk-module-template')

          @git_path = PDK::Util.which('git')
          if @git_path.nil?
            raise PDK::CLI::FatalError, _("Unable to find git binary")
          end

          clone_result = PDK::CLI::Exec.execute(@git_path, 'clone', @path_or_url, temp_dir)
          unless clone_result[:exit_code] == 0
            PDK.logger.error clone_result[:stdout]
            PDK.logger.error clone_result[:stderr]
            raise PDK::CLI::FatalError, _("Unable to clone git repository '%{repo}' to '%{dest}'") % {:repo => @path_or_url, :dest => temp_dir}
          end
          @path = temp_dir
          @repo = @path_or_url
        end

        @moduleroot_dir = File.join(@path, 'moduleroot')
        validate_module_template!

        yield self
      ensure
        cleanup
      end

      def metadata
        if @repo
          ref_result = PDK::CLI::Exec.execute(@git_path, '--git-dir', File.join(@path, '.git'), 'describe', '--all', '--long')
          if ref_result[:exit_code] == 0
            {'template-url' => @repo, 'template-ref' => ref_result[:stdout].strip}
          else
            {}
          end
        end
      end

      def cleanup
        # If we cloned a git repo to get the templates, clean it up
        if @repo
          FileUtils.remove_dir(@path)
        end
      end

      def validate_module_template!
        unless File.directory?(@path)
          raise ArgumentError, _("The specified template '%{path}' is not a directory") % {:path => @path}
        end

        unless File.directory?(@moduleroot_dir)
          raise ArgumentError, _("The template at '%{path}' does not contain a moduleroot directory") % {:path => @path}
        end
      end

      def files_in_template
        @files ||= Dir.glob(File.join(@moduleroot_dir, "**", "*"), File::FNM_DOTMATCH).select { |template_path|
          File.file?(template_path) && !File.symlink?(template_path)
        }.map { |template_path|
          template_path.sub(/\A#{Regexp.escape(@moduleroot_dir)}#{Regexp.escape(File::SEPARATOR)}/, '')
        }
      end

      def config_for(dest_path)
        if @config.nil?
          config_path = File.join(@path, 'config_defaults.yml')

          if File.file?(config_path) && File.readable?(config_path)
            begin
              @config = YAML.load(File.read(config_path))
            rescue
              PDK.logger.warn(_("'%{file}' is not a valid YAML file") % {:file => config_path})
              @config = {}
            end
          else
            @config = {}
          end
        end

        file_config = @config.fetch(:global, {})
        file_config.merge(@config.fetch(dest_path, {}))
      end

      def render(&block)
        rendered_files = files_in_template.each do |template_file|
          case File.extname(template_file)
          when ".erb"
            engine = ERBEngine
            dest_path = template_file.sub(/\.erb\Z/, '')
          else
            engine = PlainEngine
            dest_path = template_file
          end

          PDK.logger.debug(_("Rendering '%{template}'...") % {:template => template_file})

          begin
            dest_content = engine.render(File.join(@moduleroot_dir, template_file), {:configs => config_for(dest_path)})
          rescue => e
            error_msg = _(
              "Failed to render template '%{template}'\n" +
              "%{exception}: %{message}"
              ) % {:template => template_file, :exception => e.class, :message => e.message}
            raise PDK::CLI::FatalError.new(error_msg, 1)
          end

          yield dest_path, dest_content
        end
      end

      class PlainEngine
        def self.render(path, _)
          if File.file?(path) && File.readable?(path)
            File.read(path)
          else
            nil
          end
        end
      end

      class ERBEngine < OpenStruct
        def initialize(hash)
          # Support modulesync style instance variable
          if hash.has_key?(:configs)
            @configs = hash[:configs]
          end
          super
        end

        def self.render(path, data)
          ERBEngine.new(data).render(path)
        end

        def render(path)
          if File.file?(path) && File.readable?(path)
            ::ERB.new(File.read(path), nil, '-').result(binding)
          else
            nil
          end
        end
      end
    end
  end
end
