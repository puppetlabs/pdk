require 'pdk'

module PDK
  module CLI
    class ExecGroup
      # Execution Group (ExecGroup) factory.
      #
      # @param message [String] A name or message for this group. Provided for backwards compatibility during refactor
      #
      # @param create_options [Hash] A hash options used during creation of the ExecGroup.  This are not passed to the new object
      # @option create_options :parallel [Boolean] Whether the group should be executed in Parallel (True) or Serial (False)
      #
      # @param group_opts [Hash] A hash of options used to configure the execution group.  Provided for backwards compatibility during refactor
      #
      # @return [ExecGroup]
      def self.create(message, create_options = {}, group_opts = {})
        if create_options[:parallel]
          ParallelExecGroup.new(message, group_opts)
        else
          SerialExecGroup.new(message, group_opts)
        end
      end

      # Base class for an Exection Group
      #
      # @param message [String] A name or message for this group. Provided for backwards compatibility during refactor
      #
      # @param opts [Hash] A hash of options used to configure the execution group. Provided for backwards compatibility during refactor
      #
      # @api private
      def initialize(_message, opts = {})
        @options = opts
      end

      # Register something to execute as a group
      #
      # @param block [Block] A block of ruby to execute
      #
      # @api private
      def register(&_block)
        raise PDK::CLI::FatalError, 'No block registered' unless block_given?
      end

      # The return code of running all registered blocks
      #
      # @return [int] The highest exit code from the blocks
      #
      # @abstract
      def exit_code; end
    end

    # Executes registered blocks in serial
    #
    # @see PDK::CLI::ExecGroup
    class SerialExecGroup < ExecGroup
      def initialize(message, opts = {})
        super(message, opts)
        @procs = []
      end

      def register(&block)
        super(&block)

        @procs << block
      end

      def exit_code
        exit_codes = @procs.map(&:call)
        exit_codes.nil? ? 0 : exit_codes.max
      end
    end

    # Executes registered blocks in parallel using Ruby threads
    #
    # @see PDK::CLI::ExecGroup
    class ParallelExecGroup < ExecGroup
      def initialize(message, opts = {})
        super(message, opts)
        @threads = []
        @exit_codes = []
      end

      def register(&block)
        super(&block)

        # TODO: This executes the thread immediately, whereas the SerialExecGroup executes only when exit_code
        # is called.  Need to change this so it uses a kind of ThreadPool to limit to number on concurrent jobs
        # and only starts on the call to exit_code
        # e.g. max_threads = No. of CPUs
        @threads << Thread.new do
          @exit_codes << yield
        end
      end

      def exit_code
        @threads.each(&:join)
        return 0 if @exit_codes.empty?
        @exit_codes.max
      end
    end
  end
end
