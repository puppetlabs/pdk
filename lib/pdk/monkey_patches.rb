require 'tty-prompt'

module TTY
  class Prompt
    class Reader
      class WinConsole
        def get_char_non_blocking # rubocop:disable Style/AccessorMethodName
          WinAPI.getch.chr
        end
      end
    end
  end
end
