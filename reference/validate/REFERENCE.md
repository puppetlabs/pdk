# PDK Validate Reference

## Base Class

All validators inherit from the [`PDK::Validate::Validator`][PDK::Validate::Validator] base class.

### Abstract Validators

There are two types of abstract validator classes that all concrete implementations inherit from:

- [`PDK::Validate::ExternalValidator`][PDK::Validate::ExternalValidator]
- [`PDK::Validate::InternalRubyValidator`][PDK::Validate::InternalRubyValidator]

These abstract classes inherit from [`PDK::Validate::Validator`][PDK::Validate::Validator].

### Helper / Utility Classes

There are two classes that contain helper methods or provide a framework for grouping validators together:

- [`PDK::Validate::InvokableValidator`][PDK::Validate::InvokableValidator]
- [`PDK::Validator::ValidatorGroup`][PDK::Validator::ValidatorGroup]

These helper/utility classes inherit from [`PDK::Validate::Validator`][PDK::Validate::Validator].

#### **ExternalValidator**

These are for validators that are external commands within the Ruby bundled environment.

#### **InternalRubyValidator**

This is for validators written in Ruby that are part of the PDK codebase (i.e. not an external tool).
They need to be executed in the Ruby environment that the PDK ships with.

#### **InvokableValidator**

Base class for file based validators.
This is a helper class for methods to handle file parsing - e.g. skipping files that match a pattern passed in.

#### **ValidatorGroup**

Creates a group of validators!

## Entry Point / Instantiation

- Validators are loaded in [`PDK::Validate`][PDK::Validate::Validator]
- A list of validators is generated based upon their availability and validity for the context
- A [`PDK::CLI::ExecGroup`][PDK::CLI::ExecGroup] is created with the validators and the `prepare_invoke!` method called upon each of them.
The concrete implementations just pass to the `super` impl of this method, either:
  - [`PDK::Validate::InvokableValidator.prepare_invoke!`](https://github.com/puppetlabs/pdk/blob/6b1aec6f819fcf154e1417d8ef6a4340578b749a/lib/pdk/validate/invokable_validator.rb#L38-L46)
  - [`PDK::Validate::InternalRubyValidator.prepare_invoke!`](https://github.com/puppetlabs/pdk/blob/6b1aec6f819fcf154e1417d8ef6a4340578b749a/lib/pdk/validate/external_command_validator.rb#L119-L169)

## Execution

- Each validator instance is invoked with the `invoke` method (which takes a [`PDK::Report`](https://github.com/puppetlabs/pdk/blob/6b1aec6f819fcf154e1417d8ef6a4340578b749a/lib/pdk/report.rb) object as it's one and only arg)
- The concrete implementations just pass to the `super` impl of this method, either:
  - [`PDK::Validate::InvokableValidator.invoke` -> `PDK::Validate.invoke`](https://github.com/puppetlabs/pdk/blob/6b1aec6f819fcf154e1417d8ef6a4340578b749a/lib/pdk/validate/validator.rb#L112-L115)
  - [`PDK::Validate::InternalRubyValidator.invoke`](https://github.com/puppetlabs/pdk/blob/6b1aec6f819fcf154e1417d8ef6a4340578b749a/lib/pdk/validate/external_command_validator.rb#L171-L201)
- The `super.invoke` methods in turn will:
  - Usually run `prepare_invoke!` again
  - Run preperatory methods either defined within the class, or implementations in the concrete classes (_that needed specific logic_)
  - Global vars will potentially be populated with the necessary values to perform the validation tasks
- Validation begins! Usually this is done within the abstract base class in a generic way, which is possible after all expectations are set in prior preparatory steps
- Results are returned:
  - Exit code of the `ExecGroup`
  - The `Report`

## Current Validation Capabilities

The current validators can be categorised in to either:

- Internal Ruby validator (i.e. bespoke Ruby code)
- External validator (i.e. another app / gem)

### External Validators

#### **Metadata**

For both module root `metadata.json` and those defined in the tasks bundled with a module under `tasks/`.

- Validates `metadata.json`:
  - Uses [`metadata-json-lint`](https://github.com/voxpupuli/metadata-json-lint) gem
  - Sets `--strict-dependencies` option
- Validates `metadata.json` && `tasks/*.json`:
  - Uses either:
    - `JSON::Ext::Parser` (C extension)
    - `JSON::Pure::Parser` (native Ruby - preferred)

#### **Puppet**

For manifests and EPP templates.

- Validates `**/*.epp`:
  - Uses `puppet epp validate`
  - Mitigates limitations in the puppet parser functionality:
    - Sets up an empty tempdir to act as modulepath
    - Modifies parser output to include targets not listed
    - Some basic sanitiation
- Validates `**/*.pp`:
  - Uses `puppet-lint` gem
  - Modifies parser output to include targets not listed
- Validates `**/*.pp` and `plans/**/*.pp`:
  - Uses `puppet parser validate`
  - Significant amount of processing of the output
  - Modifies parser output to include targets not listed

#### **Ruby**

For all Ruby files within the module.

- Validates `**/**.rb`:
  - Uses `rubocop` gem
  - Basic processing of output

### Internal Ruby Validators

#### **Control Repo**

- Validates `environment.conf`:
  - Permitted settings defined in `ALLOWED_SETTINGS`

#### **Tasks**

For tasks defined in the `tasks/` folder of a module.

- Validates `tasks/*.json`:
  - Performs schema check aainst the [Forge Task Schema](https://forgeapi.puppet.com/schemas/task.json)
- Validates `tasks/**/*`:
  - Performs simple name check: `%r{\A[a-z][a-z0-9_]*\Z}`

#### **YAML**

- Validates `**/*.yaml`, `**/*.yml`, `**/*.eyaml` (_if a control repo_), `**/*.eyml` (_if a control repo_):
  - Simple `YAML.safe_load` performed with the permitted tags defined in `YAML_ALLOWLISTED_CLASSES`
  - Some logic to have more specifity around violations based on type of exception thrown

[PDK::Validate::Validator]:             https://github.com/puppetlabs/pdk/blob/6b1aec6f819fcf154e1417d8ef6a4340578b749a/lib/pdk/validate/validator.rb
[PDK::Validate::ExternalValidator]:     https://github.com/puppetlabs/pdk/blob/6b1aec6f819fcf154e1417d8ef6a4340578b749a/lib/pdk/validate/external_command_validator.rb
[PDK::Validate::InternalRubyValidator]: https://github.com/puppetlabs/pdk/blob/6b1aec6f819fcf154e1417d8ef6a4340578b749a/lib/pdk/validate/internal_ruby_validator.rb
[PDK::Validate::InvokableValidator]:    https://github.com/puppetlabs/pdk/blob/6b1aec6f819fcf154e1417d8ef6a4340578b749a/lib/pdk/validate/invokable_validator.rb
[PDK::Validator::ValidatorGroup]:       https://github.com/puppetlabs/pdk/blob/6b1aec6f819fcf154e1417d8ef6a4340578b749a/lib/pdk/validate/validator_group.rb
[PDK::CLI::ExecGroup]:                  https://github.com/puppetlabs/pdk/blob/6b1aec6f819fcf154e1417d8ef6a4340578b749a/lib/pdk/cli/exec_group.rb