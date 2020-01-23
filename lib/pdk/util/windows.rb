module PDK
  module Util
    #:nocov:
    def on_windows?
      # Ruby only sets File::ALT_SEPARATOR on Windows and the Ruby standard
      # requiring features to be initialized and without side effect.
      #
      # This should _NOT_ be mocked in tests. Code using this detection cannot
      # be mocked (e.g. Windows API calls) and if mocked, will most likely cause
      # false test failures on non-Windows platforms
      !!File::ALT_SEPARATOR # rubocop:disable Style/DoubleNegation This is fine. Cannot use Gem.win_platform? as that is commonly mocked
    end
    module_function :on_windows?

    module Windows
      WIN32_FALSE = 0
      module File; end

      if PDK::Util.on_windows?
        require 'pdk/util/windows/api_types'
        require 'pdk/util/windows/string'
        require 'pdk/util/windows/file'
        require 'pdk/util/windows/process'
      end
    end
    #:nocov:
  end
end
