# pick 

The shortest path to better modules: Puppet Infrastructure Construction Kit

A CLI tool to facilitate easy, unified development workflows for Puppet modules.

![pick logo using puppet dag shapes](docs/logo.png)

## Installation

1. Install `pick` into your Ruby installation with:

```
$ gem install pick
```

## Usage

### Generate a new module

To get started, generate a new module from the default template.

1. Run the `pick generate module` command, specifying the name of the new module:

```
pick generate module new_module
```

This generates the basic components of a new module and initializes Git for you. The `pick generate` command sets some default values based on your environment. Check the `metadata.json` to make sure that these values are correct. The new module now contains all the infrastructure to use the other capabilities of `pick`.

### Generate a new resource provider

If you need to manage a specific resource that is not covered by either Puppet's basic resource types or an existing module, create a new resource provider.

1. In the module's directory, run `pick generate provider` command, specifying the new provider name, as well as any attributes along with their data types.

For example:

```
pick generate provider new_provider String:content 'Enum[absent, present]:ensure'
```

This creates all the files required to define a resource type, its provider, and the associated basic tests. In this example, the resource type has an `ensure` property with the expected values, and a `String` property named `content`. If your types use Bash special characters, such as 'Enum[absent, present]:ensure' above, you must quote to avoid issues with the shell.


### Run static analysis

The default template provides tools for running static analysis of your new module. Static tests run quickly, but they provide only a basic check of the well-formedness of the module and syntax of its files.

1. In the module's directory, run:

```
pick test static
```

This displays results in the console:

```
Running static analysis on `new_module`:
* ruby syntax: OK!
* puppet syntax: OK!
[...]
```

### Run unit tests

The default template sets up [rspec](http://rspec.info/) for Ruby-level unit testing, and [rspec-puppet](https://github.com/rodjek/rspec-puppet/) for catalog-level unit testing. 

1. In the module's directory, run all unit tests with:

```
pick test unit
```

### Manage code with version control

Version control is critical when infrastructure is described in code. If you don't have an established version control routine, `pick` provides a set of commands to get you started.

1. From your module's directory, download and apply changes from your upstream repository:

```
pick update [--source=git_url] # download and apply changes from upstream
````

2. After you make changes, add all of your changes and commit to Git with:

```
pick commit
```

3. Push your commit to Git with:

```
pick upload [--destination=git_url] [--environment=environment]
```

<!-- // TODO: git hosting services (integration); code manager workflow integration; CI/CD Integration -->


## Reference

### `pick generate module` command

Generates a new module.

Usage:

```
pick generate module [--namespace=forge_user] [--github-user=github_user] [--template-url=git_url] [--license=spdx_identifier] [--vcs=vcs_provider] [--target-dir=directory] module_name
```

The `pick generate module` command accepts the following arguments. Arguments are optional unless specified.

#### `--namespace=forge_user`

Specifies the Forge username that will host this module. This is used globally to identify your contributions. Defaults to the local part of your mail address (before the @ symbol), if available.

#### `--github-user=github_user`

Specifies the [GitHub](https://github.com) user that will host this module. Defaults to the namespace. If you don't use GitHub to publish your module, you can ignore this.

#### `--template-url=git_url`

Overrides the template to use for this module. If possible, please contribute your improvements back to the default template at [puppetlabs/pick](https://github.com/puppetlabs/pick).

#### `--license=spdx_identifier`

Specifies the license this module is written under. See https://spdx.org/licenses/ for a list of open source licenses, or use `proprietary`. Defaults to `Apache-2.0`.

#### `--vcs=vcs_provider`

Specifies the version control driver. Valid values: `git`, `none`. Default: `git`.

#### `--target-dir=directory`

Specifies where the new module should be located. Defaults to the current working directory: `directory/forge_user-module_name`. 

#### `module_name`

**Required**. Specifies the name of the module being created. 

### `pick generate provider` command

Generates a new resource provider.

Usage:

```
pick generate provider [--template-url=git_url] provider_name [data_type:attribute_name]*
```

The `pick generate provider` command accepts the following arguments. Arguments are optional unless specified.

#### `--template-url=git_url`

Overrides the template to use for this module. If possible please contribute your improvements back to the default template at [puppetlabs/pick](https://github.com/puppetlabs/pick).

#### `provider_name`

**Required**. Specifies the name of the resource provider being created.

#### `data_type:attribute_name`

Specifies a list of attributes with their expected data types, such as `'Enum[absent, present]:ensure'`. If not specified, the data type will have no attributes.

### `pick test static` command

Runs all static tests. Any errors are displayed to the console and reported in the report-file, if requested. The exitcode is non-zero when errors occur.

```
pick test static [--list] [--tests=test_list] [--report-file=file_name] [--report-format=format]
```
#### `--list`

Displays a list of configured static tests and their descriptions. Using this option lists the tests without running them.

#### `--tests=test_list`

A comma-separated list of tests to run. Use this during development to pinpoint a single failing test. See the `--list` output for allowed values.

#### `--report-file=file_name`

Specifies a filename to which to write the test results. If no filename is specified, no report is created.

#### `--report-format=format`

Specifies the format of the report. Valid values: `junit`, `text`. Default: `junit`.

#### `pick test unit` command

Runs unit tests. Any errors are displayed to the console and reported in the report-file, if requested. The exitcode is non-zero when errors occur.

Usage:

```
pick test unit [--list] [--tests=test_list] [--report-file=file_name] [--report-format=format] [runner_options]
```

#### `--list`

Displays a list of unit tests and their descriptions. Using this option lists the tests without running them.

#### `--tests=test_list`

A comma-separated list of tests to run. Use this during development to pinpoint a single failing test. See the `--list` output for allowed values.

#### `--report-file=file_name`

Specifies a filename to which to write the test results. If no filename is specified, no report is created.

#### `--report-format=format`

Specifies the format of the report. Valid values: `junit`, `text`. Default: `junit`.

#### `runner_options`

<!-- this is a cop-out; alternatives are surfacing the real runner to advanced users, or completely wrapping the runner's interface -->

Specifies options to pass through to the actual test-runner. In the default template (and most commonly across modules), this is [rspec](https://relishapp.com/rspec/rspec-core/docs/command-line).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/puppetlabs/pick.

