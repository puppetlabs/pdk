require 'pdk'

module PDK
  module Validate
    autoload :ExternalCommandValidator, 'pdk/validate/external_command_validator'
    autoload :InternalRubyValidator, 'pdk/validate/internal_ruby_validator'
    autoload :InvokableValidator, 'pdk/validate/invokable_validator'
    autoload :Validator, 'pdk/validate/validator'
    autoload :ValidatorGroup, 'pdk/validate/validator_group'

    module ControlRepo
      autoload :ControlRepoValidatorGroup, 'pdk/validate/control_repo/control_repo_validator_group'
      autoload :EnvironmentConfValidator, 'pdk/validate/control_repo/environment_conf_validator'
    end

    module Metadata
      autoload :MetadataJSONLintValidator, 'pdk/validate/metadata/metadata_json_lint_validator'
      autoload :MetadataSyntaxValidator, 'pdk/validate/metadata/metadata_syntax_validator'
      autoload :MetadataValidatorGroup, 'pdk/validate/metadata/metadata_validator_group'
    end

    module Puppet
      autoload :PuppetEPPValidator, 'pdk/validate/puppet/puppet_epp_validator'
      autoload :PuppetLintValidator, 'pdk/validate/puppet/puppet_lint_validator'
      autoload :PuppetSyntaxValidator, 'pdk/validate/puppet/puppet_syntax_validator'
      autoload :PuppetPlanSyntaxValidator, 'pdk/validate/puppet/puppet_plan_syntax_validator'
      autoload :PuppetValidatorGroup, 'pdk/validate/puppet/puppet_validator_group'
    end

    module Ruby
      autoload :RubyRubocopValidator, 'pdk/validate/ruby/ruby_rubocop_validator'
      autoload :RubyValidatorGroup, 'pdk/validate/ruby/ruby_validator_group'
    end

    module Tasks
      autoload :TasksMetadataLintValidator, 'pdk/validate/tasks/tasks_metadata_lint_validator'
      autoload :TasksNameValidator, 'pdk/validate/tasks/tasks_name_validator'
      autoload :TasksValidatorGroup, 'pdk/validate/tasks/tasks_validator_group'
    end

    module YAML
      autoload :YAMLSyntaxValidator, 'pdk/validate/yaml/yaml_syntax_validator'
      autoload :YAMLValidatorGroup, 'pdk/validate/yaml/yaml_validator_group'
    end

    def self.validators
      validator_hash.values
    end

    def self.validator_names
      validator_hash.keys
    end

    # @api private
    def self.validator_hash
      # TODO: This isn't the most performant... But with only 6 items, it's fine
      @validator_hash ||= [
        ControlRepo::ControlRepoValidatorGroup,
        Metadata::MetadataValidatorGroup,
        Puppet::PuppetValidatorGroup,
        Ruby::RubyValidatorGroup,
        Tasks::TasksValidatorGroup,
        YAML::YAMLValidatorGroup,
      ].map { |klass| [klass.new.name, klass] }.to_h.freeze
    end

    def self.invoke_validators_by_name(context, names, parallel = false, options = {})
      instances = names.select { |name| validator_names.include?(name) }
                       .map { |name| validator_hash[name].new(context, options) }
                       .select { |instance| instance.valid_in_context? }
                       .each { |instance| instance.prepare_invoke! }
      report = PDK::Report.new

      # Nothing to validate then nothing to do.
      return [0, report] if instances.empty?

      require 'pdk/cli/exec_group'
      exec_group = PDK::CLI::ExecGroup.create(
        'Validating module using %{num_of_threads} threads' % { num_of_threads: instances.count },
        { parallel: parallel },
        options,
      )

      instances.each do |validator|
        exec_group.register do
          validator.invoke(report)
        end
      end

      [exec_group.exit_code, report]
    end

    class ParseOutputError < StandardError; end
  end
end
