require 'pdk'

module PDK
  module Template
    module Renderer
      module V1
        # The old templating code in the PDK passed through a TemplateDir object. This class mimics the methods
        # of that old class so that existing custom templates will still function with the newer refactor templating code.
        # Methods which have no use in custom templates exist but do no nothing, for example `def render; end`
        #
        # @see https://raw.githubusercontent.com/puppetlabs/pdk/4ffd58062c77ad1e54d2fe16b16015f7207bcee8/lib/pdk/module/template_dir/base.rb
        # :nocov: This class is tested in the packaging and acceptance testing suites
        class LegacyTemplateDir
          attr_accessor :module_metadata
          attr_reader :uri

          def initialize(context, uri, path, module_metadata = {})
            @uri = uri
            @module_metadata = module_metadata
            @context = context
            @path = path
          end

          def metadata; end

          def render; end

          def object_template_for; end

          def object_config
            config_for(nil)
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
            if PDK::Util::Filesystem.file?(loc) && PDK::Util::Filesystem.readable?(loc)
              require 'yaml'

              begin
                YAML.safe_load(PDK::Util::Filesystem.read_file(loc), [], [], true)
              rescue Psych::SyntaxError => e
                PDK.logger.warn "'%{file}' is not a valid YAML file: %{problem} %{context} at line %{line} column %{column}" % {
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

          def template_path(_uri); end
        end
        # :nocov:
      end
    end
  end
end
