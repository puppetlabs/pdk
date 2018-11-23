require 'pdk/validate/metadata_validator'
require 'pdk/validate/puppet_validator'
require 'pdk/validate/ruby_validator'
require 'pdk/validate/tasks_validator'

module PDK
  module Validate
    def self.validators
      @validators ||= [MetadataValidator, PuppetValidator, RubyValidator, TasksValidator].freeze
    end

    class ParseOutputError < StandardError; end
  end
end
