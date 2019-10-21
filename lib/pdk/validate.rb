require 'pdk'

module PDK
  module Validate
    # TODO: Fix validator namespacing
    autoload :BaseValidator, 'pdk/validate/base_validator'
    autoload :MetadataJSONLint, 'pdk/validate/metadata/metadata_json_lint'
    autoload :MetadataSyntax, 'pdk/validate/metadata/metadata_syntax'
    autoload :MetadataValidator, 'pdk/validate/metadata_validator'
    autoload :PuppetEPP, 'pdk/validate/puppet/puppet_epp'
    autoload :PuppetLint, 'pdk/validate/puppet/puppet_lint'
    autoload :PuppetSyntax, 'pdk/validate/puppet/puppet_syntax'
    autoload :PuppetValidator, 'pdk/validate/puppet_validator'
    autoload :Rubocop, 'pdk/validate/ruby/rubocop'
    autoload :RubyValidator, 'pdk/validate/ruby_validator'
    autoload :TasksValidator, 'pdk/validate/tasks_validator'
    autoload :YAMLValidator, 'pdk/validate/yaml_validator'

    class Tasks
      autoload :Name, 'pdk/validate/tasks/name'
      autoload :MetadataLint, 'pdk/validate/tasks/metadata_lint'
    end

    class YAML
      autoload :Syntax, 'pdk/validate/yaml/syntax'
    end

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
