module PDK
  module Util
    module Windows
      module File; end

      if Gem.win_platform?
        require 'pdk/util/windows/api_types'
        require 'pdk/util/windows/string'
        require 'pdk/util/windows/file'
      end
    end
  end
end
