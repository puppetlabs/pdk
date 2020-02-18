require 'pdk'

module PDK
  module Validate
    autoload :ExternalCommandValidator, 'pdk/validate/external_command_validator'
    autoload :InternalRubyValidator, 'pdk/validate/internal_ruby_validator'
    autoload :InvokableValidator, 'pdk/validate/invokable_validator'
    autoload :Validator, 'pdk/validate/validator'
    autoload :ValidatorGroup, 'pdk/validate/validator_group'

    module Metadata
      autoload :MetadataJSONLintValidator, 'pdk/validate/metadata/metadata_json_lint_validator'
      autoload :MetadataSyntaxValidator, 'pdk/validate/metadata/metadata_syntax_validator'
      autoload :MetadataValidatorGroup, 'pdk/validate/metadata/metadata_validator_group'
    end

    module YAML
      autoload :YAMLSyntaxValidator, 'pdk/validate/yaml/yaml_syntax_validator'
      autoload :YAMLValidatorGroup, 'pdk/validate/yaml/yaml_validator_group'
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

    module Puppet
      autoload :PuppetEPPValidator, 'pdk/validate/puppet/puppet_epp_validator'
      autoload :PuppetLintValidator, 'pdk/validate/puppet/puppet_lint_validator'
      autoload :PuppetSyntaxValidator, 'pdk/validate/puppet/puppet_syntax_validator'
      autoload :PuppetValidatorGroup, 'pdk/validate/puppet/puppet_validator_group'
    end

    def self.validators
      validator_hash.values
    end

    def self.validator_names
      validator_hash.keys
    end

    # @api private
    def self.validator_hash
      # TODO: This isn't the most performant... But with only 5 items, it's fine
      @validator_hash ||= [
        Metadata::MetadataValidatorGroup,
        Puppet::PuppetValidatorGroup,
        Ruby::RubyValidatorGroup,
        Tasks::TasksValidatorGroup,
        YAML::YAMLValidatorGroup,
      ].map { |klass| [klass.new.name, klass] }.to_h.freeze
    end

    # Creates instances of Validators by name
    # @param options [Array[String]] Array of validator names to instantiate
    # @param options [Hash] Options to pass to the validators
    # @return Array[PDK::Validate::Validator] An array of validator objects
    def self.instantiate_validators_by_name(names, options = {})
      names.select { |name| validator_names.include?(name) }
           .map { |name| validator_hash[name].new(options) }
    end

    # Invokes instances of Validators
    # @param instances Array[PDK::Validate::Validator] An array of validator objects to invoke
    # @param parallel [Boolean] Whether to run the validators in parallel or serial
    # @param options [Hash] Options to pass to the validator executor
    # @return [Integer] The aggregated exitcode of all the validators
    # @return [PDK::Report] The aggregatd report from running all the validators
    def self.invoke_validators(instances, parallel = false, options = {})
      instances.each { |instance| instance.prepare_invoke! }
      report = PDK::Report.new

      # Nothing to validate then nothing to do.
      return [0, report] if instances.empty?

      require 'pdk/cli/exec_group'
      exec_group = PDK::CLI::ExecGroup.create(
        _('Validating module using %{num_of_threads} threads' % { num_of_threads: instances.count }),
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

    # Helper method to instantiate and invoke validators by name
    # @param options [Array[String]] Array of validator names to invoke
    # @param parallel [Boolean] Whether to run the validators in parallel or serial
    # @param options [Hash] Options to pass to the validators
    # @return [Integer] The aggregated exitcode of all the validators
    # @return [PDK::Report] The aggregatd report from running all the validators
    # @see PDK::Validate.invoke_validators
    def self.invoke_validators_by_name(names, parallel = false, options = {})
      invoke_validators(
        instantiate_validators_by_name(names, options),
        parallel,
        options,
      )
    end

    class ParseOutputError < StandardError; end
  end
end
