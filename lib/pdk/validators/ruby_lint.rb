require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'

module PDK
  module Validate
    class RubyLint < BaseValidator
      def self.name
        'ruby-lint'
      end

      def self.cmd
        'rubocop'
      end
    end
  end
end
