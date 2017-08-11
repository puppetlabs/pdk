# pdk [![Build Status](https://travis-ci.org/puppetlabs/pdk.svg?branch=master)](https://travis-ci.org/puppetlabs/pdk) [![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/x70e2fqllbaootpd?svg=true)](https://ci.appveyor.com/project/puppetlabs/pdk) [![Coverage Status](https://coveralls.io/repos/github/puppetlabs/pdk/badge.svg?branch=master)](https://coveralls.io/github/puppetlabs/pdk?branch=master)


A CLI to facilitate easy, unified development workflows for Puppet modules. `pdk` is a key part of the Puppet Development Kit, the shortest path to better modules.

## Installation

Download and install the newest package matching your platform from [here](https://drive.google.com/drive/folders/0Bz0tCHSb1u41alR4MmZfRHBTV1k?usp=sharing). If you are using Windows, please remember to close any open PowerShell windows.

### Windows

On Windows you should run PDK from PowerShell and `pdk` will be available in your PowerShell prompt after installation.

If the `pdk` command does not appear, check that the `PuppetDevelopmentKit` PowerShell module is loaded in your PowerShell prompt:

```
Get-Module -Name PuppetDevelopmentKit
```

If no output is returned, load the `PuppetDevelopmentKit` module by running the following command:

```
Import-Module -Name PuppetDevelopmentKit
```

> Note: On PowerShell version 3 and above, PowerShell modules are loaded automatically so this step shouldn't be necessary.

You should set your script execution policy to at least [RemoteSigned](https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.security/set-executionpolicy), if it's not already, to allow the PowerShell integration to work.

You can check your ExecutionPolicy by running the following command from a PowerShell prompt:

```
Get-ExecutionPolicy
```

To set the `ExecutionPolicy`, run the following command:

```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
```

If you can't change the system `ExecutionPolicy`, you can change the `ExecutionPolicy` for just the current session by using the `Scope` paramter:

```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

For more information about PowerShell `ExecutionPolicies` or how to change them, see [about_Execution_Policies](http://go.microsoft.com/fwlink/?LinkID=135170).

## Usage

### Generate a new module

To get started, generate a new module from the default template.

1. Run the `pdk new module` command, specifying the name of the new module:

```
pdk new module my_module
```

This generates the basic components of a new module. The `pdk new module` command sets some default metadata values based on your environment. Check the `metadata.json` to make sure that these values are correct. The new module now contains all the infrastructure to use the other capabilities of `pdk`.

### Running validations

The default template provides tools for running static validations of your new module. Validations run quickly, but they provide only a basic check of the well-formedness of the module and syntax of its files.

```
pdk validate
```

This displays results in the console:

```
pdk (INFO): Running all available validators...
[✔] Checking for missing Gemfile dependencies
[✔] Checking metadata.json
[✔] Checking Ruby code style
[...]
```

Specific validators can be run by providing the validator name (or a comma
separated list of names) as an argument to `pdk validate`.

```
$ pdk validate metadata
[✔] Checking for missing Gemfile dependencies
[✔] Checking metadata.json
```

By default each validator will automatically determine which files in the
module that it should validate, however validations can be run on specific
files or directories by providing them as arguments to `pdk validate`

```
$ pdk validate lib/
[✔] Checking for missing Gemfile dependencies
[✔] Checking Ruby code style
```

Some validators support automatic correction of detected problems (for example,
both rubocop and puppet-lint can automatically correct many common code style
problems). To enable this functionality, run `pdk validate` with the
`--auto-correct` option.

```
$ pdk validate --auto-correct
pdk (INFO): Running all available validators...
[✔] Checking for missing Gemfile dependencies
[✔] Checking metadata.json
[✔] Checking Puppet manifest style
[✔] Checking Puppet manifest syntax
[✔] Checking Ruby code style
manifests/init.pp:1:10: corrected: double quoted string containing no variables
```

#### Run in parallel

Module validation can also be run in parallel and supports the same selectors for
validators, files, and directories as non-parallel validation.

```
$ pdk validate --parallel
pdk (INFO): Running all available validators...
┌ [✔] Validating module using 3 threads
├──[✔] Checking metadata syntax (metadata.json)
├──[✔] Checking Puppet manifest syntax
├──[✔] Checking Ruby code style
├──[✔] Checking metadata style (metadata.json)
└──[✔] Checking Puppet manifest style
```

### Run unit tests

The default template sets up [rspec](http://rspec.info/) for Ruby-level unit testing, and [rspec-puppet](https://github.com/rodjek/rspec-puppet/) for catalog-level unit testing.

1. In the module's directory, run all unit tests with:

```
pdk test unit
```

<!-- // TODO: git hosting services (integration); code manager workflow integration; CI/CD Integration -->


## Reference

### `pdk new module` command

Generates a new module.

Usage:

```
pdk new module [--template-url=git_url] [--license=spdx_identifier] module_name [target_dir]
```

The `pdk new module` command accepts the following arguments and options. Arguments are optional unless otherwise specified.

#### `--template-url=git_url`

Overrides the template to use for this module. If possible, please contribute your improvements back to the default template at [puppetlabs/pdk-module-template](https://github.com/puppetlabs/pdk-module-template).

#### `--license=spdx_identifier`

Specifies the license this module is written under. See https://spdx.org/licenses/ for a list of open source licenses, or use `proprietary`. Defaults to `Apache-2.0`.

#### `--skip-interview`

Suppress interactive queries for initial values. All questions will use the default values.

#### `module_name`

**Required**. Specifies the name of the module being created. e.g.: `my_module`

#### `target_dir`

Specifies the directory that the new module will be created in. Defaults to creating a new directory with the given `module_name` inside the current directory.

### `pdk new class` command

Generates a new class and skeleton test for it in the current module.

Usage:

```
pdk new class [--template-url=git_url] <class_name>
```

e.g.

```
cd my_module
pdk new class my_class
```

#### `--template-url`

Overrides the template to use when generating this class. If this is not
specified, the template used to generate the module will be used instead. If
that template is not available, the default template at
[puppetlabs/pdk-module-template](https://github.com/puppetlabs/pdk-module-template)
will be used.

#### `class_name`

The name of the class to generate. If the class name is not inside the module
namespace (e.g. module name is `apt` and the class name is `source`, then the
module name will automatically be prepended to the class name (e.g.
`apt::source`).

### `pdk validate` command

Runs all static validations. Any errors are reported to the console in the format requested. The exit code is non-zero when errors occur.

Usage:

```
pdk validate --list
```

```
pdk validate [--format=format[:target]] [validations] [targets*]
```

#### `--list`

Displays a list of available validations and their descriptions. Using this option lists the tests without running them.

#### `--format=format[:target]`

Specifies the format of the output. Valid values: `junit`, `text`. Default: `text`.

Optionally, you can specify a target file for the given output format with the syntax: `--format=junit:report.xml`

Multiple `--format` options can be specified as long as they all have distinct output targets.

#### `validations`

Specifies a comma separated list of validations to run (or `all`). See the `--list` output for a list of available validations. Defaults to `all` if not supplied.

#### `targets`

Specifies a list of directories or individual files to validate. Validations which are not applicable to individual files will be skipped for those files. Defaults to validating everything.

#### Additional Examples

```
$ pdk validate metadata
Running 'metadata' validation on `new_module`: OK!
```

```
$ pdk validate all lib/
Running validations on `new_module/lib`:
* ruby syntax: OK!
* puppet syntax: (no puppet manifests found)
```

### `pdk test unit` command

Runs unit tests. Any errors are displayed to the console and reported in the report-file, if requested. The exitcode is non-zero when errors occur.

Usage:

```
pdk test unit [--list] [--tests=test_list] [--format=format[:target]] [runner_options]
```

#### `--list`

Displays a list of unit tests and their descriptions. Using this option lists the tests without running them.

#### `--tests=test_list`

A comma-separated list of tests to run. Use this during development to pinpoint a single failing test. See the `--list` output for allowed values.

#### `--format=format[:target]`

Specifies the format of the output. Valid values: `junit`, `text`. Default: `text`.

Optionally, you can specify a target file for the given output format with the syntax: `--format=junit:report.xml`

Multiple `--format` options can be specified as long as they all have distinct output targets.

#### `runner_options`

<!-- this is a cop-out; alternatives are surfacing the real runner to advanced users, or completely wrapping the runner's interface -->

Specifies options to pass through to the actual test-runner. In the default template (and most commonly across modules), this is [rspec](https://relishapp.com/rspec/rspec-core/docs/command-line).

### `pdk bundle` command

This experimental command allows advanced users to execute arbitrary commands in a bundler context within the module you're currently working on. Arguments to this command are passed straight through to bundler. Careless use of this command can lead to errors later which can't be recovered by the pdk itself.

Note that for most advanced uses it is required to use the `--` to separate bundler options from pdk options. Compare the following two commands:

```
$ pdk bundle exec rake -T
bundle: illegal option -- T

```

and

```
$ pdk bundle -- exec rake -T
rake beaker                # Run beaker acceptance tests
rake beaker:sets           # List available beaker nodesets
rake beaker:ssh[set,node]  # Try to use vagrant to login to the Beaker node
rake build                 # Build puppet module package
[...]
```

## Module Compatibility

**PDK Version Compatibility:** modules created with a specific PDK version should validate against and run on all Puppet andRuby version combinations currently under maintenance (see https://docs.puppet.com/puppet/latest/about_agent.html and https://puppet.com/misc/puppet-enterprise-lifecycle)

**Module Template Compatibility:** Modules created with a specific version of the PDK will remain compatible to newer versions of the PDK with the following exceptions:
* access to new PDK functionality might require an update of the module to the current Template version
* access to a new major PDK version might require an update of the module to the current Template version, after a one year deprecation cycle
* validation against new Puppet versions might require new PDK functionality, a new major PDK version, and changes to the module itself.

## Upgrading
* In the common case, Puppet and the PDK will be forward-compatible so that minor Puppet updates will not require a new version of the PDK.
* Some new Puppet versions will require changes to the PDK. In that case, upgrading the PDK for validation prior to roll-out of Puppet is strongly recommended.



## Contributing

See the [CONTRIBUTING.md](CONTRIBUTING.md) file for development notes.
