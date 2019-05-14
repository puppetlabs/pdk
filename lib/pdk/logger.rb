require 'logger'

module PDK
  def self.logger
    @logger ||= PDK::Logger.new
  end

  class Logger < ::Logger
    WRAP_COLUMN_LIMIT = 78

    def initialize
      super(STDERR)

      # TODO: Decide on output format.
      self.formatter = proc do |severity, _datetime, _progname, msg|
        prefix = "pdk (#{severity}): "
        if msg.is_a?(Hash)
          if msg.fetch(:wrap, false)
            wrap_pattern = %r{(.{1,#{WRAP_COLUMN_LIMIT - prefix.length}})(\s+|\Z)}
            "#{prefix}#{msg[:text].gsub(wrap_pattern, "\\1\n#{' ' * prefix.length}")}\n"
          else
            "#{prefix}#{msg[:text]}\n"
          end
        else
          "#{prefix}#{msg}\n"
        end
      end

      self.level = ::Logger::INFO
    end

    def enable_debug_output
      self.level = ::Logger::DEBUG
    end

    def debug?
      level == ::Logger::DEBUG
    end
  end
end
