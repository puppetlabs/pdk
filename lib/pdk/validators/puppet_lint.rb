require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'

module PDK
  module Validate
    class PuppetLint < BaseValidator
      def self.name
        'puppet-lint'
      end

      def self.cmd
        'puppet-lint'
      end
    end
  end
end
