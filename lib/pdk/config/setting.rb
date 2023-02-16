require 'pdk'

module PDK
  class Config
    # A class for describing the setting of a {PDK::Config} setting.
    #
    # Generally, this is never instantiated manually, but is instead
    # instantiated by passing a block to {PDK::Config::Namespace#setting}.
    #
    # @example
    #
    # PDK::Config::Namespace.new('analytics') do
    #   setting :disabled do
    #     validate PDK::Config::Validator.boolean
    #     default_to { false }
    #   end
    # end
    class Setting
      attr_reader :namespace

      # It is possible to have multiple setting definitions for the same setting; for example, defining a default value with a lambda, but the
      # the validation is within a JSON schema document. These are expressed as two settings objects, and uses a single linked list to join them
      # together:
      #
      # (PDK::Config::JSONSchemaSetting) --previous_setting--> (PDK::Config::Setting)
      #
      # So in the example above, calling `default` the on the first object in the list will:
      # 1. Look at `default` on PDK::Config::JSONSchemaSetting
      # 2. If a default could not be found then it calls `default` on previous_setting
      # 3. If a default could not be found then it calls `default` on previous_setting.previous_setting
      # 4. and so on down the linked list (chain) of settings
      attr_writer :previous_setting

      # Initialises an empty setting definition.
      #
      # @param name [String,Symbol] the name of the setting.
      # @param namespace [PDK::Config::Namespace] The namespace this setting belongs to
      def initialize(name, namespace, initial_value = nil)
        @name = name.to_s
        @validators = []
        @namespace = namespace
        @value = initial_value
      end

      def qualified_name
        [namespace.name, @name].join('.')
      end

      def value
        # Duplicate arrays and hashes so that they are isolated from changes being made
        PDK::Util.deep_duplicate(@value)
      end

      def value=(obj)
        validate!(obj)
        @value = obj
      end

      def to_s
        @value.to_s
      end

      # Assign a validator to the setting. Subclasses should not override this method.
      #
      # @param validator [Hash{Symbol => [Proc,String]}]
      # @option validator [Proc] :proc a lambda that takes the setting to be
      #   validated as the argument and returns `true` if the setting is valid.
      # @option validator [String] :message a description of what the validator
      #   is testing for, that is displayed to the user as part of the error
      #   message for invalid settings.
      #
      # @raise [ArgumentError] if not passed a Hash.
      # @raise [ArgumentError] if the Hash doesn't have a `:proc` key that
      #   contains a Proc.
      # @raise [ArgumentError] if the Hash doesn't have a `:message` key that
      #   contains a String.
      #
      # @return [nil]
      def validate(validator)
        raise ArgumentError, '`validator` must be a Hash' unless validator.is_a?(Hash)
        raise ArgumentError, 'the :proc key must contain a Proc' unless validator.key?(:proc) && validator[:proc].is_a?(Proc)
        raise ArgumentError, 'the :message key must contain a String' unless validator.key?(:message) && validator[:message].is_a?(String)

        @validators << validator
      end

      # Validate a setting against the assigned validators.
      #
      # @param setting [Object] the setting being validated.
      #
      # @raise [ArgumentError] if any of the assigned validators fail to
      #   validate the setting.
      #
      # @return [nil]
      def validate!(value)
        @validators.each do |validator|
          next if validator[:proc].call(value)

          raise ArgumentError, '%{key} %{message}' % {
            key:     qualified_name,
            message: validator[:message],
          }
        end
      end

      # Assign a default value proc for the setting. Subclasses should not override this method.
      #
      # @param block [Proc] a block that is lazy evaluated when necessary in
      #   order to determine the default setting.
      #
      # @return [nil]
      def default_to(&block)
        raise ArgumentError, 'must be passed a block' unless block_given?
        @default_to = block
      end

      # Evaluate the default setting.
      #
      # @return [Object,nil] the result of evaluating the block given to
      #   {#default_to}, or `nil` if the setting has no default.
      def default
        return @default_to.call if default_block?
        # If there is a previous setting in the chain, use its default
        @previous_setting.nil? ? nil : @previous_setting.default
      end

      private

      # @return [Boolean] true if the setting has a default setting block. Subclasses should not override this method.
      def default_block?
        !@default_to.nil?
      end
    end
  end
end
