require 'pdk/validators/metadata_validator'
require 'pdk/validators/puppet_validator'
require 'pdk/validators/ruby_validator'

module PDK
  module Validate
    def self.validators
      @validators ||= [MetadataValidator, PuppetValidator, RubyValidator].freeze
    end
  end
end
