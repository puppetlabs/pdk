require 'tty-spinner'
require 'tty-which'

require 'pdk/util'

module PDK
  module CLI
    class ExecGroup
      attr_reader :commands

      def initialize(message, opts = {})
        @options = opts.merge(PDK::CLI::Util.spinner_opts_for_platform)

        unless PDK.logger.debug?
          @multi_spinner = TTY::Spinner::Multi.new("[:spinner] #{message}", @options)
          @multi_spinner.auto_spin
        end

        @threads = []
        @exit_codes = []
      end

      def register
        raise PDK::CLI::FatalError, 'No block registered' unless block_given?

        @threads << Thread.new do
          GettextSetup.initialize(File.absolute_path('../../../locales', File.dirname(__FILE__)))
          GettextSetup.negotiate_locale!(GettextSetup.candidate_locales)
          @exit_codes << yield
        end
      end

      def add_spinner(message, opts = {})
        return if PDK.logger.debug?
        @multi_spinner.register("[:spinner] #{message}", @options.merge(opts).merge(PDK::CLI::Util.spinner_opts_for_platform))
      end

      def exit_code
        @threads.each(&:join)

        exit_code = @exit_codes.max

        if exit_code.zero? && @multi_spinner
          @multi_spinner.success
        elsif @multi_spinner
          @multi_spinner.error
        end

        exit_code
      end
    end
  end
end
