require 'pick/validations/metadata'
require 'pick/validations/puppet_lint'
require 'pick/validations/puppet_parser'
require 'pick/validations/ruby_lint'

module Pick
  module Validate
    def self.validators
      @validators ||= [Metadata, PuppetLint, PuppetParser, RubyLint].freeze
    end
  end
end
