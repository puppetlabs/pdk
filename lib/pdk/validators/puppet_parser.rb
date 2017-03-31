require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'

module PDK
  module Validate
    class PuppetParser < BaseValidator
      def self.cmd
        'puppet-parser-validate'
      end
    end
  end
end
