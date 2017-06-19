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
        File.join(PDK::Util.module_root, 'bin', 'metadata-json-lint')
      end

      def self.invoke(options = {})
        PDK::Util::Bundler.ensure_bundle!
        PDK::Util::Bundler.ensure_binstubs!('metadata-json-lint')

        options[:targets] = [File.join(PDK::Util.module_root, 'metadata.json')]

        result = super

        # FIXME: this is weird so that it complies with the format
        # of the other validators which are nested
        { 'metadata' => result }
      end
    end
  end
end
