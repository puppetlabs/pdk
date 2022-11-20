require 'pdk'
require 'pdk/template/renderer'

module PDK
  module Template
    module Renderer
      module V1
        class Renderer < PDK::Template::Renderer::AbstractRenderer
          # @see PDK::Template::Renderer::AbstractRenderer.render
          def render(template_type, _name, options = {})
            render_module(options) { |*args| yield(*args) } if template_type == PDK::Template::MODULE_TEMPLATE_TYPE
          end

          # @see PDK::Template::Renderer::AbstractRenderer.has_single_item?
          def has_single_item?(item_path) # rubocop:disable Naming/PredicateName
            PDK::Util::Filesystem.exist?(single_item_path(item_path))
          end

          # @see PDK::Template::Renderer::AbstractRenderer.render_single_item
          def render_single_item(relative_file_path, template_data_hash)
            template_file = single_item_path(relative_file_path)
            return nil unless PDK::Util::Filesystem.file?(template_file) && PDK::Util::Filesystem.readable?(template_file)

            PDK.logger.debug("Rendering '%{template}'..." % { template: template_file })
            new_template_file(template_file, template_data_hash).render
          end

          # Returns the full path for a single item
          #
          # @param item_path [String] The path of the single item to render
          # @return [String]
          # @api private
          #:nocov:
          def single_item_path(item_path)
            File.join(template_root, 'object_templates', item_path)
          end
          #:nocov:

          # Helper method used during testing
          #:nocov:
          # @api private
          def new_template_file(template_file, template_data_hash)
            TemplateFile.new(template_file, template_data_hash)
          end
          #:nocov:

          # Helper method used during testing
          #:nocov:
          # @api private
          def new_legacy_template_dir(context, uri, path, module_metadata = {})
            LegacyTemplateDir.new(context, uri, path, module_metadata)
          end
          #:nocov:

          # Renders a new module
          #
          # @param options [Hash{Object => Object}] A list of options to pass through to the renderer. See PDK::Template::TemplateDir helper methods for other options
          # @see #render
          # @api private
          #:nocov: This is tested in acceptance and packaging tests
          def render_module(options = {})
            require 'pdk/template/renderer/v1/template_file'

            moduleroot_dir = File.join(template_root, 'moduleroot')
            moduleroot_init = File.join(template_root, 'moduleroot_init')

            dirs = [moduleroot_dir]
            dirs << moduleroot_init if options[:include_first_time]

            legacy_template_dir = new_legacy_template_dir(context, template_uri, template_root, options[:module_metadata] || {})

            files_in_template(dirs).each do |template_file, template_loc|
              template_file = template_file.to_s
              PDK.logger.debug("Rendering '%{template}'..." % { template: template_file })
              dest_path = template_file.sub(%r{\.erb\Z}, '')
              config = legacy_template_dir.config_for(dest_path)

              dest_status = if template_loc.start_with?(moduleroot_init)
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
                  dest_content = new_template_file(File.join(template_loc, template_file), configs: config, template_dir: legacy_template_dir).render
                rescue => error
                  error_msg = "Failed to render template '%{template}'\n" \
                              '%{exception}: %{message}' % { template: template_file, exception: error.class, message: error.message }
                  raise PDK::CLI::FatalError, error_msg
                end
              end

              yield dest_path, dest_content, dest_status
            end
          end
          #:nocov:

          # Returns all files in the given template directories
          #
          # @param dirs [Array[String]] Directories to search in
          # @param glob_suffix [Array[String]] File glob to use when searching for files. Defaults to ['**', '*']
          #
          # @return [Hash{String => String}] Key is the template file relative path and the value is the absolute path to the template directory
          # @api private
          def files_in_template(dirs, glob_suffix = ['**', '*'])
            temp_paths = []
            dirlocs = []
            dirs.each do |dir|
              raise ArgumentError, "The directory '%{dir}' doesn't exist" % { dir: dir } unless PDK::Util::Filesystem.directory?(dir)
              temp_paths += PDK::Util::Filesystem.glob(File.join(dir, *glob_suffix), File::FNM_DOTMATCH).select do |template_path|
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
  end
end
