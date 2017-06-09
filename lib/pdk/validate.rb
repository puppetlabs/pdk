require 'pdk/validators/metadata'
require 'pdk/validators/puppet_validator'
require 'pdk/validators/ruby_validator'

module PDK
  module Validate
    def self.validators
      @validators ||= [Metadata, PuppetValidator, RubyValidator].freeze
    end
  end
end
