# pdk

A CLI to facilitate easy, unified development workflows for Puppet modules. pdk is a key part of the Puppet Development Kit, the shortest path to better modules.

## Installation

1. Until Puppet Development Kit packaging is available, install `pdk` into your Ruby installation with:

```
$ gem install pdk
```

## Usage

### Generate a new module

To get started, generate a new module from the default template.

1. Run the `pdk new module` command, specifying the name of the new module:

```
pdk new module my_module
```

This generates the basic components of a new module and initializes Git for you. The `pdk new module` command sets some default values based on your environment. Check the `metadata.json` to make sure that these values are correct. The new module now contains all the infrastructure to use the other capabilities of `pdk`.

### Add a new resource provider

If you need to manage a specific resource that is not covered by either Puppet's basic resource types or an existing module, create a new resource provider.

1. From within an existing module, run `pdk add provider`, specifying the new provider name as well as any attributes along with their data types.

For example:

```
pdk add provider new_provider String:content 'Enum[absent, present]:ensure'
```

This creates all the files required to define a resource type, its provider, and the associated basic tests. In this example, the resource type has an `ensure` property with the expected values, and a `String` property named `content`. If your types use Bash special characters, such as 'Enum[absent, present]:ensure' above, you must quote to avoid issues with the shell.

### Running validations

The default template provides tools for running static validations of your new module. Validations run quickly, but they provide only a basic check of the well-formedness of the module and syntax of its files.

```
pdk validate
```

This displays results in the console:

```
Running validations on `new_module`:
* ruby syntax: OK!
* puppet syntax: OK!
[...]
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
pdk new module [--template-url=git_url] [--license=spdx_identifier] [--vcs=vcs_provider] module_name [target_dir]
```

The `pdk new module` command accepts the following arguments and options. Arguments are optional unless otherwise specified.

#### `--template-url=git_url`

Overrides the template to use for this module. If possible, please contribute your improvements back to the default template at [puppetlabs/pdk](https://github.com/puppetlabs/pdk).

#### `--license=spdx_identifier`

Specifies the license this module is written under. See https://spdx.org/licenses/ for a list of open source licenses, or use `proprietary`. Defaults to `Apache-2.0`.

#### `--vcs=vcs_provider`

Specifies the version control driver. Valid values: `git`, `none`. Default: `git`.

#### `--skip-interview`

Suppress interactive queries for initial values. All questions will use the default values.

#### `module_name`

**Required**. Specifies the name of the module being created, including the namespace. e.g.: `username-my_module`

#### `target_dir`

Specifies the directory that the new module will be created in. Defaults to creating a new directory with the given `module_name` inside the current directory.

### `pdk add provider` command

Adds a new resource provider to an existing module.

Usage:

```
pdk add provider [--template-url=git_url] provider_name [data_type:attribute_name]*
```

The `pdk add provider` command accepts the following arguments. Arguments are optional unless specified.

#### `--template-url=git_url`

Overrides the template to use for this module. If possible please contribute your improvements back to the default template at [puppetlabs/pdk](https://github.com/puppetlabs/pdk).

#### `provider_name`

**Required**. Specifies the name of the resource provider being created.

#### `data_type:attribute_name`

Specifies a list of attributes with their expected data types, such as `'Enum[absent, present]:ensure'`. If not specified, the data type will have no attributes.

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

#### `pdk test unit` command

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

## Contributing

To run the `pdk` tool directly from the repository, set the environment variable `PDK_USE_SYSTEM_BINARIES` to `true`. This causes it to use the system installed binaries, instead of relying on the puppet-sdk-vanagon packaging. Currently required is a ruby (2.1, or later), and git.

```
PowerShell: $env:PDK_USE_SYSTEM_BINARIES = "true"
cmd.exe:    set PDK_USE_SYSTEM_BINARIES=true
bash:       export PDK_USE_SYSTEM_BINARIES=true
```

In cases where `pdk` needs to run in a working directory outside the cloned repository, either set `BUNDLE_GEMFILE` to the pdk's Gemfile location, or install and use the [binstubs of bundler](http://bundler.io/v1.15/bundle_binstubs.html), which are small proxy binaries, that set up the environment for running the tool.

```
# assuming ~/bin is already on your path:
bundle binstubs pdk --path ~/bin
```

Bug reports and pull requests are welcome on GitHub at https://github.com/puppetlabs/pdk.
