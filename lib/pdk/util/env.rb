require 'pdk'
require 'forwardable'

module PDK
  module Util
    class Env
      class << self
        extend Forwardable

        def_delegators :env_hash, :[], :key?, :fetch, :select, :reject

        def []=(key, value)
          if Gem.win_platform?
            PDK::Util::Windows::Process.set_environment_variable(key, value)
          else
            ENV[key] = value
          end
        end

        def env_hash
          if Gem.win_platform?
            PDK::Util::Windows::Process.environment_hash
          else
            ENV
          end
        end
      end
    end
  end
end
