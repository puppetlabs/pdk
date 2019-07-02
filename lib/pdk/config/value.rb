module PDK
  class Config
    # A class for describing the value of a {PDK::Config} setting.
    #
    # Generally, this is never instantiated manually, but is instead
    # instantiated by passing a block to {PDK::Config::Namespace#value}.
    #
    # @example
    #
    # PDK::Config::Namespace.new('analytics') do
    #   value :disabled do
    #     validate PDK::Config::Validator.boolean
    #     default_to { false }
    #   end
    # end
    class Value
      # Initialises an empty value definition.
      #
      # @param name [String,Symbol] the name of the value.
      def initialize(name)
        @name = name
        @validators = []
      end

      # Assign a validator to the value.
      #
      # @param validator [Hash{Symbol => [Proc,String]}]
      # @option validator [Proc] :proc a lambda that takes the value to be
      #   validated as the argument and returns `true` if the value is valid.
      # @option validator [String] :message a description of what the validator
      #   is testing for, that is displayed to the user as part of the error
      #   message for invalid values.
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

      # Validate a value against the assigned validators.
      #
      # @param key [String] the name of the value being validated.
      # @param value [Object] the value being validated.
      #
      # @raise [ArgumentError] if any of the assigned validators fail to
      #   validate the value.
      #
      # @return [nil]
      def validate!(key, value)
        @validators.each do |validator|
          next if validator[:proc].call(value)

          raise ArgumentError, _('%{key} %{message}') % {
            key:     key,
            message: validator[:message],
          }
        end
      end

      # Assign a default value.
      #
      # @param block [Proc] a block that is lazy evaluated when necessary in
      #   order to determine the default value.
      #
      # @return [nil]
      def default_to(&block)
        raise ArgumentError, _('must be passed a block') unless block_given?
        @default_to = block
      end

      # Evaluate the default value block.
      #
      # @return [Object,nil] the result of evaluating the block given to
      #   {#default_to}, or `nil` if the value has no default.
      def default
        default? ? @default_to.call : nil
      end

      # @return [Boolean] true if the value has a default value block.
      def default?
        !@default_to.nil?
      end
    end
  end
end
