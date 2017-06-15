require 'pdk'
require 'pdk/cli/exec'
require 'pdk/util/bundler'
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

      def self.invoke(options = {})
        # PDK::Util::Bundler.ensure_binstubs!(
      end
    end
  end
end
