require 'pdk'

module PDK
  class Config
    autoload :IniFile, 'pdk/config/ini_file'
    autoload :IniFileSetting, 'pdk/config/ini_file_setting'
    autoload :JSON, 'pdk/config/json'
    autoload :JSONSchemaNamespace, 'pdk/config/json_schema_namespace'
    autoload :JSONSchemaSetting, 'pdk/config/json_schema_setting'
    autoload :LoadError, 'pdk/config/errors'
    autoload :Namespace, 'pdk/config/namespace'
    autoload :Setting, 'pdk/config/setting'
    autoload :Validator, 'pdk/config/validator'
    autoload :YAML, 'pdk/config/yaml'

    # Create a new instance of the PDK Configuration
    # @param options [Hash[String => Object]] Optional hash to override configuration options
    # @option options [String]                        'system.path'                 Path to the system PDK configuration file
    # @option options [String]                        'system.module_defaults.path' Path to the system module answers PDK configuration file
    # @option options [String]                        'user.path'                   Path to the user PDK configuration file
    # @option options [String]                        'user.module_defaults.path'   Path to the user module answers PDK configuration file
    # @option options [String]                        'user.analytics.path'         Path to the user analytics PDK configuration file
    # @option options [PDK::Context::AbstractContext] 'context'                     The context that the configuration should be created in
    def initialize(options = nil)
      options = {} if options.nil?
      @config_options = {
        'system.path'                 => PDK::Config.system_config_path,
        'system.module_defaults.path' => PDK::Config.system_answers_path,
        'user.path'                   => PDK::Config.user_config_path,
        'user.module_defaults.path'   => PDK::AnswerFile.default_answer_file_path,
        'user.analytics.path'         => PDK::Config.analytics_config_path,
        'context'                     => PDK.context,
      }.merge(options)
    end

    # The system level configuration settings.
    # @return [PDK::Config::Namespace]
    # @api private
    def system_config
      local_options = @config_options
      @system_config ||= PDK::Config::JSON.new('system', file: local_options['system.path']) do
        mount :module_defaults, PDK::Config::JSON.new(file: local_options['system.module_defaults.path'])
      end
    end

    # The user level configuration settings.
    # @return [PDK::Config::Namespace]
    # @api private
    def user_config
      local_options = @config_options
      @user_config ||= PDK::Config::JSON.new('user', file: local_options['user.path']) do
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

        # Display the feature flags
        mount :pdk_feature_flags, PDK::Config::Namespace.new('pdk_feature_flags') do
          setting 'available' do
            default_to { PDK.available_feature_flags }
          end

          setting 'requested' do
            default_to { PDK.requested_feature_flags }
          end
        end
      end
    end

    # The project level configuration settings.
    # @return [PDK::Config::Namespace]
    # @api private
    def project_config
      context = @config_options['context']
      @project ||= PDK::Config::Namespace.new('project') do
        if context.is_a?(PDK::Context::ControlRepo)
          mount :environment, PDK::ControlRepo.environment_conf_as_config(File.join(context.root_path, 'environment.conf'))
        end

        mount :validate, PDK::Config::YAML.new('validate', file: File.join(context.root_path, 'pdk.yaml'), persistent_defaults: true) do
          setting 'ignore' do
            default_to { [] }
          end
        end
      end
    end

    # Resolves *all* filtered settings from all namespaces
    #
    # @param filter [String] Only resolve setting names which match the filter. See PDK::Config::Namespace.be_resolved? for matching rules
    # @return [Hash{String => Object}] All resolved settings for example {'user.module_defaults.author' => 'johndoe'}
    def resolve(filter = nil)
      all_scopes.values.reverse.reduce({}) do |result, method_name|
        result.merge(send(method_name).resolve(filter))
      end
    end

    # Returns a configuration setting by name. This name can either be a String, Array or parameters e.g. These are equivalent
    # - PDK.config.get('user.a.b.c')
    # - PDK.config.get(['user', 'a', 'b', 'c'])
    # - PDK.config.get('user', 'a', 'b', 'c')
    # @param root [Array[String], String] The root setting name or the entire setting name as a single string
    # @param keys [String] The child names of the setting
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

      get_within_scopes(name[1..-1], [name[0]])
    end

    # Returns a configuration setting by name, using scope precedence rules. If no scopes are passed, then all scopes are queried using the default precedence rules
    # @setting_name [String, Array[String]] The setting name to retrieve without the leading scope name e.g. Use 'setting' instead of 'system.setting'
    # @scopes [Nil, Array[String]] The list of scopes, in order, to query in turn for the setting_name. Invalid or missing scopes are ignored.
    # @return [PDK::Config::Namespace, Object, nil] The value of the configuration setting. Returns nil if it does no exist
    def get_within_scopes(setting_name, scopes = nil)
      raise ArgumentError, _('Expected an Array but got \'%{klass}\' for scopes') % { klass: scopes.class } unless scopes.nil? || scopes.is_a?(Array)
      raise ArgumentError, _('Expected an Array or String but got \'%{klass}\' for setting_name') % { klass: setting_name.class } unless setting_name.is_a?(Array) || setting_name.is_a?(String)

      setting_arr = setting_name.is_a?(String) ? split_key_string(setting_name) : setting_name
      all_scope_names = all_scopes.keys

      # Use only valid scope names
      scopes = scopes.nil? ? all_scope_names : scopes & all_scope_names

      scopes.each do |scope_name|
        value = traverse_object(send(all_scopes[scope_name]), *setting_arr)
        return value unless value.nil?
      end
      nil
    end

    # Yields a configuration setting value by name, using scope precedence rules. If no scopes are passed, then all scopes are queried using the default precedence rules
    # @setting_name [String, Array[String]] The setting name to retrieve without the leading scope name e.g. Use 'setting' instead of 'system.setting'
    # @scopes [Nil, Array[String]] The list of scopes, in order, to query in turn for the setting_name. Invalid or missing scopes are ignored.
    # @yield [PDK::Config::Namespace, Object] The value of the configuration setting. Does not yield if the setting does not exist or is nil
    def with_scoped_value(setting_name, scopes = nil)
      raise ArgumentError, _('must be passed a block') unless block_given?
      value = get_within_scopes(setting_name, scopes)
      yield value unless value.nil?
    end

    # Sets a configuration setting by name. This name can either be a String or an Array
    # - PDK.config.set('user.a.b.c', ...)
    # - PDK.config.set(['user', 'a', 'b', 'c'], ...)
    # @param key [String, Array[String]] The name of the configuration key to change
    # @param value [Object] The value to set the configuration setting to
    # @param options [Hash] Changes the behaviour of the setting process
    # @option options [Boolean] :force Disables any munging or array processing, and sets the value as it is. Default is false
    # @return [Object] The new value of the configuration setting
    def set(key, value, options = {})
      options = {
        force: false,
      }.merge(options)

      names = key.is_a?(String) ? split_key_string(key) : key
      raise ArgumentError, _('Invalid configuration names') if names.nil? || !names.is_a?(Array) || names.empty?
      scope_name = names[0]
      raise ArgumentError, _("Unknown configuration root '%{name}'") % { name: scope_name } if all_scopes[scope_name].nil?
      deep_set_object(value, options[:force], send(all_scopes[scope_name]), *names[1..-1])
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
        PDK.config.set(%w[user analytics disabled], true)
      else
        PDK.config.set(%w[user analytics disabled], !answers['enabled'])
      end

      PDK.logger.info(text: post_message, wrap: true)
    end

    private

    #:nocov: This is a private method and is tested elsewhere
    def traverse_object(object, *names)
      return nil if object.nil? || !object.respond_to?(:[])
      return nil if names.nil?
      # It's possible to pass in empty names at the root traversal layer
      # but this should _only_ happen at the root namespace level
      if names.empty?
        return (object.is_a?(PDK::Config::Namespace) ? object : nil)
      end

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

    #:nocov:
    # Returns all known scope names and their associated method name to call, to query the scope
    # Note - Order is important. This dictates the resolution precedence order (topmost is processed first)
    # @return [Hash[String, Symbol]] A hash of the scope name then method name to call to query the scope (as a Symbol)
    def all_scopes
      # Note - Order is important. This dictates the resolution precedence order (topmost is processed first)
      {
        'project' => :project_config,
        'user'    => :user_config,
        'system'  => :system_config,
      }.freeze
    end

    #:nocov: This is a private method and is tested elsewhere
    # Deeply traverses an object tree via `[]` and sets the last
    # element to the value specified.
    #
    # Creating any missing parent hashes during the traversal
    def deep_set_object(value, force, namespace, *names)
      raise ArgumentError, _('Missing or invalid namespace') unless namespace.is_a?(PDK::Config::Namespace)
      raise ArgumentError, _('Missing a name to set') if names.nil? || names.empty?

      name = names.shift
      current_value = namespace[name]

      # If the next thing in the traversal chain is another namespace, set the value using that child namespace.
      if current_value.is_a?(PDK::Config::Namespace)
        return deep_set_object(value, force, current_value, *names)
      end

      # We're at the end of the name traversal
      if names.empty?
        if force || !current_value.is_a?(Array)
          namespace[name] = value
          return value
        end

        # Arrays are a special case if we're not forcing the value
        namespace[name] = current_value << value unless current_value.include?(value)
        return value
      end

      # Need to generate a deep hash using the current remaining names
      # So given an origin *names of ['a', 'b', 'c', 'd'] and a value 'foo',
      # we eventually want a hash of `{"b"=>{"c"=>{"d"=>"foo"}}}`
      #
      # The code above has already shifted the first element so we currently have
      # name : 'a'
      # names: ['b', 'c', 'd']
      #
      #
      # First we need to pop off the last element ('d') in this case as we need to set that in the `reduce` call below
      # So now we have:
      # name : 'a'
      # names: ['b', 'c']
      # last_name : 'd'
      last_name = names.pop
      # Using reduce and an accumulator, we create the nested hash from the deepest value first. In this case the deepest value
      # is the last_name, so the starting condition is {"d"=>"foo"}
      # After the first iteration ('c'), the accumulator has {"c"=>{"d"=>"foo"}}}
      # After the last iteration ('b'), the accumulator has {"b"=>{"c"=>{"d"=>"foo"}}}
      hash_value = names.reverse.reduce(last_name => value) { |accumulator, item| { item => accumulator } }

      # If the current value is nil, then it can't be a namespace or an existing value
      # or
      # If the current value is not a Hash and are forcing the change.
      if current_value.nil? || (force && !current_value.is_a?(Hash))
        namespace[name] = hash_value
        return value
      end

      raise ArgumentError, _("Unable to set '%{key}' to '%{value}' as it is not a Hash") % { key: namespace.name + '.' + name, value: hash_value } unless current_value.is_a?(Hash)

      namespace[name] = current_value.merge(hash_value)
      value
    end
    #:nocov:
  end
end
