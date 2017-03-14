require 'pick/validators/metadata'
require 'pick/validators/puppet_lint'
require 'pick/validators/puppet_parser'
require 'pick/validators/ruby_lint'

module Pick
  module Validate
    def self.validators
      @validators ||= [Metadata, PuppetLint, PuppetParser, RubyLint].freeze
    end
  end
end
