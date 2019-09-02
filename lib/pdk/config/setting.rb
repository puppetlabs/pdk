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

      def value # rubocop:disable Style/TrivialAccessors
        @value
      end

      def value=(obj)
        validate!(obj)
        @value = obj
      end

      def to_s
        @value.to_s
      end

      # Assign a validator to the setting.
      # TODO: Do not override?
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
        raise ArgumentError, _('`validator` must be a Hash') unless validator.is_a?(Hash)
        raise ArgumentError, _('the :proc key must contain a Proc') unless validator.key?(:proc) && validator[:proc].is_a?(Proc)
        raise ArgumentError, _('the :message key must contain a String') unless validator.key?(:message) && validator[:message].is_a?(String)

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

          raise ArgumentError, _('%{key} %{message}') % {
            key:     qualified_name,
            message: validator[:message],
          }
        end
      end

      # Assign a default value proc for the setting.
      # TODO: Do not override
      #
      # @param block [Proc] a block that is lazy evaluated when necessary in
      #   order to determine the default setting.
      #
      # @return [nil]
      def default_to(&block)
        raise ArgumentError, _('must be passed a block') unless block_given?
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

      # @return [Boolean] true if the setting has a default setting block.
      # TODO: Do not override
      def default_block?
        !@default_to.nil?
      end
    end
  end
end
