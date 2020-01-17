require 'pdk'

module PDK
  module Validate
    # TODO: Fix validator namespacing
    autoload :BaseValidator, 'pdk/validate/base_validator'
    autoload :ExternalCommandValidator, 'pdk/validate/external_command_validator'
    autoload :InternalRubyValidator, 'pdk/validate/internal_ruby_validator'
    autoload :InvokableValidator, 'pdk/validate/invokable_validator'
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
    autoload :Validator, 'pdk/validate/validator'
    autoload :ValidatorGroup, 'pdk/validate/validator_group'
    autoload :YAMLValidator, 'pdk/validate/yaml_validator'

    module Metadata
      autoload :MetadataJSONLintValidator, 'pdk/validate/metadata/metadata_json_lint_validator'
      autoload :MetadataSyntaxValidator, 'pdk/validate/metadata/metadata_syntax_validator'
      autoload :MetadataValidatorGroup, 'pdk/validate/metadata/metadata_validator_group'
    end

    module Puppet
      autoload :PuppetEPPValidator, 'pdk/validate/puppet/puppet_epp_validator'
      autoload :PuppetLintValidator, 'pdk/validate/puppet/puppet_lint_validator'
      autoload :PuppetSyntaxValidator, 'pdk/validate/puppet/puppet_syntax_validator'
      autoload :PuppetValidatorGroup, 'pdk/validate/puppet/puppet_validator_group'
    end

    module Ruby
      autoload :RubyRubocopValidator, 'pdk/validate/ruby/ruby_rubocop_validator'
      autoload :RubyValidatorGroup, 'pdk/validate/ruby/ruby_validator_group'
    end

    module Tasks
      autoload :TasksNameValidator, 'pdk/validate/tasks/tasks_name_validator'
      autoload :TasksMetadataLintValidator, 'pdk/validate/tasks/tasks_metadata_lint_validator'
      autoload :TasksValidatorGroup, 'pdk/validate/tasks/tasks_validator_group'
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
      ].freeze
    end

    class ParseOutputError < StandardError; end
  end
end
