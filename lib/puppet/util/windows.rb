module Puppet
  module Util
    module Windows
      module File; end

      if Gem.win_platform?
        # these reference platform specific gems
        require 'puppet/util/windows/api_types'
        require 'puppet/util/windows/string'
        require 'puppet/util/windows/file'
      end
    end
  end
end
