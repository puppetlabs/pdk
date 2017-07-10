# pdk [![Build Status](https://travis-ci.org/puppetlabs/pdk.svg?branch=master)](https://travis-ci.org/puppetlabs/pdk) [![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/x70e2fqllbaootpd?svg=true)](https://ci.appveyor.com/project/puppetlabs/pdk)


A CLI to facilitate easy, unified development workflows for Puppet modules. pdk is a key part of the Puppet Development Kit, the shortest path to better modules.

## Installation

1. Until Puppet Development Kit packaging is available, install `pdk` into your Ruby installation with:

```
$ gem install pdk
```

For default usage, you'll also need to have `git`, and `bundle` (from [bundler](http://bundler.io/)) on your system PATH.

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

Overrides the template to use for this module. If possible, please contribute your improvements back to the default template at [puppetlabs/pdk-module-template](https://github.com/puppetlabs/pdk-module-template).

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

### `pdk new class` command

Generates a new class and skeleton test for it in the current module.

Usage:

```
pdk new class [--template-url=git_url] <class_name> [parameter_name[:parameter_type]] [parameter_name[:parameter_type]] ...
```

e.g.

```
cd my_module
pdk new class my_class "ensure:Enum['absent', 'present']" version:String
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

#### `parameter_name[:parameter_type]`

If the class should take parameters, they can be specified on the command line
to be added to the generated class. Optionally, the data type of the parameter
can be specified along with the parameter name, separated by a colon. Any
number of parameters can be provided on the command line.

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

In cases where `pdk` needs to run in a working directory outside the cloned repository, either set `BUNDLE_GEMFILE` to the pdk's Gemfile location, or install and use the [binstubs of bundler](http://bundler.io/v1.15/bundle_binstubs.html), which are small proxy binaries, that set up the environment for running the tool.

```
# assuming ~/bin is already on your path:
bundle binstubs pdk --path ~/bin
```

Bug reports and pull requests are welcome on GitHub at https://github.com/puppetlabs/pdk.

### Running tests

pdk has three testing rake tasks

#### spec

Run unit tests.

#### acceptance:local

Run acceptance tests on the current pdk code. These tests are executed on commits and pull requests to this repo using both travis and appveyor.

#### acceptance:package

Run acceptance tests against a package install. This task is for Puppet's packaging CI, and contributors outside of Puppet, Inc. don't need to worry about executing it. It uses [beaker](https://github.com/puppetlabs/beaker) to provision a VM, fetch and install a pdk installation package, and then run the acceptance tests on that VM.
It requires some environment variables to be set in order to specify what beaker will set up:

Environment Variable | Usage
---------------------|------
**SHA** | The SHA or tag of a package build i.e. the folder name on the build server that packages will be found in.
**TEST_TARGET** | A beaker-hostgenerator string for the OS of the VM you want to test on e.g. _redhat7-64workstation._ or _windows2012r2-64workstation._ (The period character after workstation is required by beaker-hostgenerator).
**BUILD_SERVER** | (Only required if the tests will run on a Windows VM). The hostname of the build server that hosts packages. A Puppet JIRA ticket ([BKR-1109](https://tickets.puppetlabs.com/browse/BKR-1109)) has been filed to update beaker so this would never be required.

On completion of this testing task, the results from the VM will be available in a folder named _archive_.

### Release Process

1. Bump the version in `lib/pdk/version.rb`.
1. In a clean checkout of master, run `bundle exec rake changelog`.
1. Edit PR titles and tags, until `bundle exec rake changelog` output makes sense.
1. Commit and PR the changes.
1. When the PR is merged, get a clean checkout of the merged commit, and run `bundle exec rake release[upstream]` (where "upstream" is your local name of the puppetlabs remote)
1. Profit!
1. Update `lib/pdk/version.rb` with `x.y.z.pre` version bump, commit, and PR to prepare for next release.
