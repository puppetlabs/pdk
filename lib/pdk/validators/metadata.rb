require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'
require 'pdk/util/bundler'

module PDK
  module Validate
    class Metadata < BaseValidator
      def self.name
        'metadata'
      end

      def self.cmd
        'metadata-json-lint'
      end

      def self.parse_targets(options)
        [File.join(PDK::Util.module_root, 'metadata.json')]
      end
    end
  end
end
