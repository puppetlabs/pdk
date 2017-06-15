require 'logger'
require 'tty-spinner'

module PDK
  def self.logger
    @logger ||= PDK::Logger.new
  end

  class Logger < ::Logger
    def initialize
      # TODO: Decide where log output goes, probably stderr?
      super(STDOUT)

      # TODO: Decide on output format.
      self.formatter = proc do |severity, _datetime, _progname, msg|
        "pdk (#{severity}): #{msg}\n"
      end

      self.level = ::Logger::INFO
    end

    def enable_debug_output
      self.level = ::Logger::DEBUG
    end

    # These two output_* methods are just a way to not try to do the spinner stuff on Windows for now.
    def spinner_output_start(message)
      if Gem.win_platform?
        $stderr.print "#{message}... "
      else
        @spinner = TTY::Spinner.new("[:spinner] #{message}")
        @spinner.auto_spin
      end
    end
    
    def spinner_output_end(state)
      if Gem.win_platform?
        $stderr.print (state == :success) ? _("done.\n") : _("FAILURE!\n")
      else
        if state == :success
          @spinner.success
        else
          @spinner.error
        end
    
        remove_instance_variable(:@spinner)
      end
    end
  end
end
