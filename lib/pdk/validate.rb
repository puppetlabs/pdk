require 'pdk/validate/metadata_validator'
require 'pdk/validate/puppet_validator'
require 'pdk/validate/ruby_validator'
require 'pdk/validate/tasks_validator'
require 'pdk/validate/yaml_validator'

module PDK
  module Validate
    def self.validators
      @validators ||= [
        MetadataValidator,
        YAMLValidator,
        PuppetValidator,
        RubyValidator,
        TasksValidator,
      ].freeze
    end

    class ParseOutputError < StandardError; end
  end
end
