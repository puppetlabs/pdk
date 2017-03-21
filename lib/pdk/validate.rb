require 'pdk/validators/metadata'
require 'pdk/validators/puppet_lint'
require 'pdk/validators/puppet_parser'
require 'pdk/validators/ruby_lint'

module PDK
  module Validate
    def self.validators
      @validators ||= [Metadata, PuppetLint, PuppetParser, RubyLint].freeze
    end
  end
end
