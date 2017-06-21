require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'

module PDK
  module Validate
    class PuppetParser < BaseValidator
      def self.name
        'puppet-parser'
      end

      def self.cmd
        'puppet'
      end

      def self.pattern
        '**/**.pp'
      end

      def self.spinner_text
        _('Checking Puppet manifest syntax')
      end

      def self.parse_options(_options, targets)
        ['parser', 'validate'].concat(targets)
      end

      def self.parse_output(report, json_data)
        return
      end
    end
  end
end
