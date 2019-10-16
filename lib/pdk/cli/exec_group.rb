require 'pdk'

module PDK
  module CLI
    class ExecGroup
      def initialize(message, opts = {})
        require 'pdk/cli/util'
        @options = opts.merge(PDK::CLI::Util.spinner_opts_for_platform)

        if PDK::CLI::Util.interactive?
          require 'pdk/cli/util/spinner'

          @spinner = if parallel?
                       TTY::Spinner::Multi.new("[:spinner] #{message}", @options)
                     else
                       TTY::Spinner.new("[:spinner] #{message}", @options)
                     end
          @spinner.auto_spin
        end

        @threads_or_procs = []
        @exit_codes = []
      end

      def parallel?
        @options[:parallel].nil? ? true : @options[:parallel]
      end

      def register(&block)
        raise PDK::CLI::FatalError, _('No block registered') unless block_given?

        @threads_or_procs << if parallel?
                               Thread.new do
                                 GettextSetup.initialize(File.absolute_path('../../../locales', File.dirname(__FILE__)))
                                 GettextSetup.negotiate_locale!(GettextSetup.candidate_locales)
                                 @exit_codes << yield
                               end
                             else
                               block
                             end
      end

      def add_spinner(message, opts = {})
        require 'pdk/cli/util'

        return unless PDK::CLI::Util.interactive?
        @spinner.register("[:spinner] #{message}", @options.merge(opts).merge(PDK::CLI::Util.spinner_opts_for_platform))
      end

      def exit_code
        if parallel?
          @threads_or_procs.each(&:join)
        else
          @exit_codes = @threads_or_procs.map(&:call)
        end

        exit_code = @exit_codes.max

        if exit_code.zero? && @spinner
          @spinner.success
        elsif @spinner
          @spinner.error
        end

        exit_code
      end
    end
  end
end
