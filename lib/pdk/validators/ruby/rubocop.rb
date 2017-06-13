require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'
require 'pdk/validators/ruby_validator'

module PDK
  module Validate
    class Rubocop < BaseValidator
      def self.name
        'rubocop'
      end

      def self.cmd
        'rubocop'
      end

      def self.parse_options(options, targets)
        cmd_options = if options[:format] && options[:format] == 'junit'
          ['--format', 'json']
        else
          ['--format', 'clang']
        end

        cmd_options.concat(targets)
      end
    end
  end
end
