require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'

module PDK
  module Validate
    class Metadata < BaseValidator
      def self.cmd
        'metadata-json-lint'
      end
    end
  end
end
