require 'pdk'

module PDK
  class Config
    autoload :JSON, 'pdk/config/json'
    autoload :JSONSchemaNamespace, 'pdk/config/json_schema_namespace'
    autoload :JSONSchemaSetting, 'pdk/config/json_schema_setting'
    autoload :LoadError, 'pdk/config/errors'
    autoload :Namespace, 'pdk/config/namespace'
    autoload :Setting, 'pdk/config/setting'
    autoload :Validator, 'pdk/config/validator'
    autoload :YAML, 'pdk/config/yaml'

    # Create a new instance of the PDK Configuration
    # @param options [Hash[String => String]] Optional hash to override configuration options
    # @option options [String] 'system.path'                 Path to the system PDK configuration file
    # @option options [String] 'system.module_defaults.path' Path to the system module answers PDK configuration file
    # @option options [String] 'user.path'                   Path to the user PDK configuration file
    # @option options [String] 'user.module_defaults.path'   Path to the user module answers PDK configuration file
    # @option options [String] 'user.analytics.path'         Path to the user analytics PDK configuration file
    def initialize(options = nil)
      options = {} if options.nil?
      @config_options = {
        'system.path'                 => PDK::Config.system_config_path,
        'system.module_defaults.path' => PDK::Config.system_answers_path,
        'user.path'                   => PDK::Config.user_config_path,
        'user.module_defaults.path'   => PDK::AnswerFile.default_answer_file_path,
        'user.analytics.path'         => PDK::Config.analytics_config_path,
      }.merge(options)
    end

    # The user configuration settings.
    # @deprecated This method is only provided as a courtesy until the `pdk set config` CLI and associated changes in this class, are completed.
    #             Any read-only operations should be using `.get` or `.pdk_setting`
    # @return [PDK::Config::Namespace]
    def user
      user_config
    end

    # The system level configuration settings.
    # @return [PDK::Config::Namespace]
    # @api private
    def system_config
      local_options = @config_options
      @system ||= PDK::Config::JSON.new('system', file: local_options['system.path']) do
        mount :module_defaults, PDK::Config::JSON.new(file: local_options['system.module_defaults.path'])
      end
    end

    # The user level configuration settings.
    # @return [PDK::Config::Namespace]
    # @api private
    def user_config
      local_options = @config_options
      @user ||= PDK::Config::JSON.new('user', file: local_options['user.path']) do
        mount :module_defaults, PDK::Config::JSON.new(file: local_options['user.module_defaults.path'])

        # Due to the json-schema gem having issues with Windows based paths, and only supporting Draft 05 (or less) do
        # not use JSON validation yet.  Once PDK drops support for EOL rubies, we will be able to use the json_schemer gem
        # Which has much more modern support
        # Reference - https://github.com/puppetlabs/pdk/pull/777
        # Reference - https://tickets.puppetlabs.com/browse/PDK-1526
        mount :analytics, PDK::Config::YAML.new(file: local_options['user.analytics.path'], persistent_defaults: true) do
          setting :disabled do
            validate PDK::Config::Validator.boolean
            default_to { PDK::Config.bolt_analytics_config.fetch('disabled', true) }
          end

          setting 'user-id' do
            validate PDK::Config::Validator.uuid
            default_to do
              require 'securerandom'

              PDK::Config.bolt_analytics_config.fetch('user-id', SecureRandom.uuid)
            end
          end
        end
      end
    end

    # Resolves *all* filtered settings from all namespaces
    #
    # @param filter [String] Only resolve setting names which match the filter. See PDK::Config::Namespace.be_resolved? for matching rules
    # @return [Hash{String => Object}] All resolved settings for example {'user.module_defaults.author' => 'johndoe'}
    def resolve(filter = nil)
      system_config.resolve(filter).merge(user_config.resolve(filter))
    end

    # Returns a configuration setting by name. This name can either be a String, Array or parameters e.g. These are equivalent
    # - PDK.config.get('user.a.b.c')
    # - PDK.config.get(['user', 'a', 'b', 'c'])
    # - PDK.config.get('user', 'a', 'b', 'c')
    # @return [PDK::Config::Namespace, Object, nil] The value of the configuration setting. Returns nil if it does no exist
    def get(root, *keys)
      return nil if root.nil? || root.empty?

      if keys.empty?
        if root.is_a?(Array)
          name = root
        elsif root.is_a?(String)
          name = split_key_string(root)
        else
          return nil
        end
      else
        name = [root].concat(keys)
      end

      case name[0]
      when 'user'
        traverse_object(user_config, *name[1..-1])
      when 'system'
        traverse_object(system_config, *name[1..-1])
      else
        nil
      end
    end

    # Gets a named setting using precedence from the user and system levels
    # Note that name must NOT include user or system prefix
    def pdk_setting(*name)
      value = get(['user'].concat(name))
      value.nil? ? get(['system'].concat(name)) : value
    end

    def self.bolt_analytics_config
      file = PDK::Util::Filesystem.expand_path('~/.puppetlabs/bolt/analytics.yaml')
      PDK::Config::YAML.new(file: file)
    rescue PDK::Config::LoadError => e
      PDK.logger.debug _('Unable to load %{file}: %{message}') % {
        file:    file,
        message: e.message,
      }
      PDK::Config::YAML.new
    end

    def self.analytics_config_path
      PDK::Util::Env['PDK_ANALYTICS_CONFIG'] || File.join(File.dirname(PDK::Util.configdir), 'puppet', 'analytics.yml')
    end

    def self.user_config_path
      File.join(PDK::Util.configdir, 'user_config.json')
    end

    def self.system_config_path
      File.join(PDK::Util.system_configdir, 'system_config.json')
    end

    def self.system_answers_path
      File.join(PDK::Util.system_configdir, 'answers.json')
    end

    def self.json_schemas_path
      File.join(__dir__, 'config')
    end

    # return nil if not exist
    def self.json_schema(name)
      File.join(json_schemas_path, name + '_schema.json')
    end

    def self.analytics_config_exist?
      PDK::Util::Filesystem.file?(analytics_config_path)
    end

    def self.analytics_config_interview!
      require 'pdk/cli/util'

      return unless PDK::CLI::Util.interactive?

      pre_message = _(
        'PDK collects anonymous usage information to help us understand how ' \
        'it is being used and make decisions on how to improve it. You can ' \
        'find out more about what data we collect and how it is used in the ' \
        "PDK documentation at %{url}.\n",
      ) % { url: 'https://puppet.com/docs/pdk/latest/pdk_install.html' }
      post_message = _(
        'You can opt in or out of the usage data collection at any time by ' \
        'editing the analytics configuration file at %{path} and changing ' \
        "the '%{key}' value.",
      ) % {
        path: PDK::Config.analytics_config_path,
        key:  'disabled',
      }

      questions = [
        {
          name:     'enabled',
          question: _('Do you consent to the collection of anonymous PDK usage information?'),
          type:     :yes,
        },
      ]

      require 'pdk/cli/util/interview'

      PDK.logger.info(text: pre_message, wrap: true)
      prompt = TTY::Prompt.new(help_color: :cyan)
      interview = PDK::CLI::Util::Interview.new(prompt)
      interview.add_questions(questions)
      answers = interview.run

      if answers.nil?
        PDK.logger.info _('No answer given, opting out of analytics collection.')
        PDK.config.user['analytics']['disabled'] = true
      else
        PDK.config.user['analytics']['disabled'] = !answers['enabled']
      end

      PDK.logger.info(text: post_message, wrap: true)
    end

    private

    #:nocov: This is a private method and is tested elsewhere
    def traverse_object(object, *names)
      return nil if object.nil? || !object.respond_to?(:[])
      return nil if names.nil? || names.empty?

      name = names.shift
      value = object[name]
      if names.empty?
        return value if value.is_a?(PDK::Config::Namespace)
        # Duplicate arrays and hashes so that they are isolated from changes being made
        (value.is_a?(Hash) || value.is_a?(Array)) ? value.dup : value
      else
        traverse_object(value, *names)
      end
    end
    #:nocov:

    #:nocov: This is a private method and is tested elsewhere
    # Takes a string representation of a setting and splits into its constituent setting parts e.g.
    # 'user.a.b.c' becomes ['user', 'a', 'b', 'c']
    # @return [Array[String]] The string split into each setting name as an array
    def split_key_string(key)
      raise ArgumentError, _('Expected a String but got \'%{klass}\'') % { klass: key.class } unless key.is_a?(String)
      key.split('.')
    end
    #:nocov:
  end
end
