require 'pdk'
require 'forwardable'

module PDK
  module Util
    class Env
      class WindowsEnv
        extend Forwardable

        # Note, these delegators may not have case insensitive keys
        def_delegators :env_hash, :fetch, :select, :reject

        def []=(key, value)
          PDK::Util::Windows::Process.set_environment_variable(key, value)
        end

        def key?(key)
          !env_hash.keys.find { |item| key.casecmp(item).zero? }.nil?
        end

        def [](key)
          env_hash.each do |item, value|
            next unless key.casecmp(item).zero?
            return value
          end
          nil
        end

        private

        def env_hash
          PDK::Util::Windows::Process.environment_hash
        end
      end

      class << self
        extend Forwardable

        def_delegators :implementation, :key?, :[], :[]=, :fetch, :select, :reject

        def implementation
          @implementation ||= Gem.win_platform? ? WindowsEnv.new : ENV
        end
      end
    end
  end
end
