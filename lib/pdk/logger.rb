require 'logger'
require 'pdk'

module PDK
  class Logger < ::Logger
    WRAP_COLUMN_LIMIT = 78

    def initialize
      super(STDERR)
      @sent_messages = {}

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

    def warn_once(*args)
      hash = args.inspect.hash
      return if (@sent_messages[::Logger::WARN] ||= {}).key?(hash)
      @sent_messages[::Logger::WARN][hash] = true
      warn(*args)
    end

    def enable_debug_output
      self.level = ::Logger::DEBUG
    end

    def debug?
      level == ::Logger::DEBUG
    end
  end
end
