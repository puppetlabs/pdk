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

      def self.parse_targets(_options)
        [File.join(PDK::Util.module_root, 'metadata.json')]
      end

      def self.parse_options(_options, targets)
        cmd_options = ['--format', 'json']

        cmd_options.concat(targets)
      end

      def self.parse_output(report, json_data)
        return if json_data.empty?

        json_data.delete('result')
        json_data.keys.each do |type|
          json_data[type].each do |offense|
            report.add_event(
              file:     'metadata.json',
              source:   cmd,
              message:  offense['msg'],
              test:     offense['check'],
              severity: type,
              state:    :failure,
            )
          end
        end
      end
    end
  end
end
