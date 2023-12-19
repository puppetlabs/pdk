# PDK command reference

PDK commands accept arguments and options to customize behavior.

## `pdk build` command

Builds a module package that can be published on the Forge.

Usage:

Within the module directory:

```language-bourne
pdk build [--target-dir=<PATH>] [--force]
```

For example:

```bash
pdk build --target-dir=mymodules/my_module/pkg
```

To learn more, see [building module packages](pdk_building_module_packages.md).
For step-by-step instructions, see the [build a
module](pdk_building_module_packages.md#build-a-module) topic.

|Argument|Description|Values|Default|
|--------|-----------|------|-------|
|`--force`|Skips the prompts and builds the module package. Overwrites any existing package, if one exists.|None.|By default, prompts are enabled.|
|`--target-dir=<PATH>`|The target directory where you want PDK to write the package.|A directory path.|Defaults to `pkg` directory in the module.|

## `pdk get config` command

Retrieves the resolved user configuration for PDK, including all available
layers of configuration.

Usage:

```bash
pdk get config <key>
```

For example: `pdk config get user.analytics.disabled`

|Argument|Description|Value|Default|
|--------|-----------|-----|-------|
|`<key>`|The name, or name prefix, of the setting key to retrieve. Raises an error if the setting does not exist.|The full name of the setting, such as `user.analytics.disabled`. Alternatively, the beginning of the setting name, which retrieves all settings that match. For example, `user.analytics` returns all settings that start with user.analytics`user.analytics`.|If no `<key>` is passed, the command returns all configuration keys that it finds.|

## `pdk remove config` command

Unsets one or more values from the given configuration key.

Usage:

```bash
pdk remove config <key> <value>
```

To unset all values for a given key:

```bash
pdk remove config [--all] <key>
```

|Argument|Description|Value|Default|
|--------|-----------|-----|-------|
|`<key>`|Required. The configuration key to delete values for.|The full name of the setting, such as `user.analytics.disabled`. Alternatively, the beginning of the setting name, which retrieves all settings that match. For example, `user.analytics` returns all settings that start with user.analytics`user.analytics`.|No default. The `<key>` is required.|
|`<value>`|Required. The value to delete for the specified key. To delete all values, use the `--all` option instead of specifying values.|One or more specified values for the given configuration key.|No default. Either a `<value>` or the `--all` option is required for normal usage.|
|`--all`|Empties all values for the given key.|None.|When this option is passed, empties all values for the specified key.|

## `pdk set config` command

Sets, updates, or adds to the values in the given configuration key and outputs
the new values.

Usage:

```bash
pdk set config [--type|--as <typename>] [--force] <key> [<value>]
```

For example: `pdk set config --type boolean user.analytics.disabled false`

|Argument|Description|Value|Default|
|--------|-----------|-----|-------|
|`<key>`|Required. The configuration key to set, change, or add values for.|The full name of the setting, such as `user.analytics.disabled`.|No default. The `<key>` is required.|
|`<value>`|Required. The value to set for the specified key.|One or more valid values for the specified `<key>`.|No default. One or more values are required.|
|`–-add`|Treats a user-defined configuration key as a multi-value key.|None.|This option treats the value as a list of values.|
|`--force`|Runs the command, making literal changes without prompting for confirmation.|None.|By default, prompts are enabled.|
|`--type`, `--as <typename>`|Specifies what type the value should be. Useful if the type cannot be inferred from the `<key>`.|Accepts values common to JSON and YAML:<ul><li>`number`: Treats the value as a number, such as `1`, `1.0`, `-1.0`.</li><li>`boolean`: Treats value as a Boolean, such as `true`, `TRUE`, `False`,`yes`, `no`.</li><li>`array`: Treats value as an array element. If given no value, treats value as an empty array.</li><li>`string`: The default type for any value.</li></ul>|By default, if the type cannot be inferred, values are treated as strings.|

## `pdk convert` command

Converts an existing module to a standardized PDK module with an infrastructure
for testing.

Usage:

Within the module directory:

```bash
pdk convert [--noop] [--force][--template-url=<GIT_URL>] [--skip-interview] [--full-interview]
```

For example:

```bash
pdk convert --template-url=https://github.com/puppetlabs/pdk-templates --skip-interview
```

To learn more, see [converting modules](pdk_converting_modules.md). For
step-by-step instructions, see the [convert a
module](pdk_converting_modules.md#convert-a-module) topic.

|Option|Description|Value|Default|
|------|-----------|-----|-------|
|`--add-tests`|Adds basic unit test templates for existing classes and defined types that do not have any tests.|None.|If not specified, unit test templates are not added.|
|`--default-template`|Converts a module to the default PDK template.|None.|If not specified, converts to default template unless you have specified a custom template.|
|`--force`|Runs the command, making changes without prompting for confirmation. This option manipulates files and is potentially destructive. Always back up your work before using this option.|None.|If not specified, the command prompts for confirmation.|
|`--full-interview`|Include interview questions related to publishing on the Forge to create module metadata.|None.|If not specified, asks only basic module metadata questions.|
|`--noop`|Runs the command in a no operation or "no-op" mode. This shows what changes PDK will make without actually executing the changes.|None.|If not specified, the command makes the requested changes.|
|`--skip-interview`|Skip interview questions and use default values to create module metadata.|None.|If not specified, asks basic module metadata questions.|
|`--template-ref=<VALUE>`|Specifies the reference to use for the specified template for this module. This option is valid only if you have specified a template with the `--template-url` option.|A template branch name, tag name, or commit SHA for the specified template.|If you have specified a custom template, or if you installed PDK as a gem, this option defaults to "main". Otherwise, defaults to the defaults to the currently installed PDK version.|
|`--template-url=<GIT_URL>`|Specifies a template to use for this module.|A valid Git URL or a path to a local template.|A valid Git URL or a path to a local template.|

## `pdk new class` command

Generates a new class and test templates for it in the current module.

Usage:

Within the module directory:

```bash
pdk new class [--template-url=<GIT_URL>] <class_name>
```

For example: `pdk new class my_class`

For step-by-step instructions, see the [create a
class](pdk_creating_modules.md#create-a-class) topic.

|Argument|Description|Value|Default|
|--------|-----------|-----|-------|
|`<class_name>`|Required. The name of the class to generate.|A class name beginning with a lowercase letter and including only lowercase letters, digits, and underscores.|No default.|
|`--template-url=<GIT_URL>`|Specifies the template to use when generating this class.|A valid Git URL or a path to a local template.|Uses the same template that was used to generate the module. If that template is not available, defaults to `[pdk-template](https://github.com/puppetlabs/pdk-template)`|

## `pdk new defined_type` command

Generates a new defined type and test templates for it in the current module.

Usage:

Within the module directory:

```bash
pdk new defined_type [--template-url=<GIT_URL>] <defined_type_name>

```

For example: `pdk new defined_type my_defined_type`

For step-by-step instructions, see [create a defined
type](pdk_creating_modules.md#create-a-defined-type) topic.

|Argument|Description|Value|Default|
|--------|-----------|-----|-------|
|`<defined_type_name>`|Required. The name of the defined type to generate.|A defined type name beginning with a lowercase letter and including only lowercase letters, digits, and underscores.|No default.|
|`--template-url=<GIT_URL>`|Specifies the template to use when generating this defined type.|A valid Git URL or path to a local template.|Uses the same template that was used to generate the module. If that template is not available, defaults to `[pdk-template](https://github.com/puppetlabs/pdk-template)` .|

## `pdk new fact` command

Generates a new custom fact with a given name using given options

Usage:

Within the module directory:

```bash
pdk new fact <fact_name>

```

For example: `pdk new fact my_fact`

|Argument|Description|Value|Default|
|--------|-----------|-----|-------|
|`<fact_name>`|Required. The name of the fact to generate.|A fact name beginning with a lowercase letter and including only lowercase letters, digits, and underscores.|No default.|

## `pdk new function` command

Generates a new function with a given name using given options

Usage:

Within the module directory:

```bash
pdk new function [--type=<value>] <function_name>

```

For example: `pdk new function my_func`

|Argument|Description|Value|Default|
|--------|-----------|-----|-------|
|`<function_name>`|Required. The name of the function to generate.|A function name beginning with a lowercase letter and including only lowercase letters, digits, and underscores.|No default.|
|`--type=<value>`|Specifies the type of function to generate.|`native` or `v4`|`native`|

## `pdk new module` command

Creates a complete module skeleton and testing templates.

Usage:

```bash
pdk new module <module_name> [--template-url=<GIT_URL>] [--license=<IDENTIFIER>] [<TARGET_DIR>] [--skip-interview] [--full-interview] 
```

For example:

```bash
pdk new module my_module --template-url=https://github.com/puppetlabs/pdk-templates --full-interview mymodules/my_module

```

To learn more, see [creating modules](pdk_creating_modules.md). For
step-by-step instructions, see the [create a module](pdk_creating_modules.md#create-a-module)
topic.

|Argument|Description|Values|Default|
|--------|-----------|------|-------|
|`<module_name>`|Required. Specifies the name of the module being created.|A module name beginning with a lowercase letter and including only lowercase letters, digits, and underscores.|No default.|
|`--full-interview`|Include interview questions related to publishing modules on the Forge to create module metadata.|None.|If not specified, PDK asks only basic module metadata questions. |
|`--license=<IDENTIFIER>`|Specifies the license for this module is written under.|See the [SPDX](https://spdx.org/licenses/) License List for a list of open source licenses, or use `proprietary`.|`Apache-2.0`|
|`--skip-interview`|Skip interview questions and use default values to create module metadata.|None.|If not specified, PDK asks basic module metadata questions.|
|`<TARGET_DIR>`|Specifies the directory that the new module will be created in.|A valid directory path.|Creates a directory with the given `module_name` inside the current directory.|
|`--template-ref=<VALUE>`|Specifies the reference to use for the specified template for this module. This option is valid only if you have specified a template with the `--template-url` option.|A template branch name, tag name, or commit SHA for the specified template.|If you have specified a custom template, or if you installed PDK as a gem, this option defaults to "main". Otherwise, defaults to the defaults to the currently installed PDK version.|
|`--template-url=<GIT_URL>`|Specifies a template to use for this module.|A valid Git URL or path to a local template.|If not specified, defaults to the `[pdk-template](https://github.com/puppetlabs/pdk-template)`|

## `pdk new task` command

Generates a new task and task metadata in the current module.

Usage:

Within the module directory:

```
pdk new task [--template-url=<GIT_URL>] <task_name>      
```

For example: `pdk new task my_task`

For step-by-step instructions, see the [create a task](pdk_creating_modules.md#create-a-task)
topic.

|Argument|Description|Value|Default|
|--------|-----------|-----|-------|
|`<task_name>`|Required. The name of the task to generate.|A task name beginning with a lowercase letter and including only lowercase letters, digits, and underscores.|No default.|
|`--template-url=<GIT_URL>`|Specifies the template to use when generating this task.|A valid Git URL or path to a local template.|Uses the same template that was used to generate the module. If that template is not available, defaults to `[pdk-template](https://github.com/puppetlabs/pdk-template)`|

## `pdk new test` command

Generates a new test for the specified Puppet object in the current module. This
test checks only whether the module compiles a catalog for the module's
supported operating system.

The generated test is named based on the defined type or class it tests in the
format `<PUPPET_OBJECT_NAME>_spec.rb`, such as `ntp_spec.rb`. Tests are located
in `/spec/classes`, for classes, or `/spec/defines`, for defined types.

Usage:

Within the module directory:

```
pdk new test [--unit] <puppet_object_name>
```

For example:

```
pdk new test --unit ntp
```

To learn more about unit testing, see [Unit testing modules](pdk_testing.md).

|Argument|Description|Value|Default|
|--------|-----------|-----|-------|
|`<puppet_object_name>`|Required. Specifies the name of the Puppet object (such as a class or defined type) to create a test for.|A valid Puppet object name, without the file extension, such as `ntp`.|No default.|
|`--unit`|Generates a new unit test.|None.|By default, creates a unit test.|

## `pdk release` command

Prepares, builds, and publishes a module to the Forge.

> **Note:** This is an experimental command as it is not fully implemented and
might change in the future.

Usage:

Within the module directory:

```bash
pdk release [--file=<value>] [--force] [--forge-token=<value>] [--forge-upload-url=<value>] [--skip-build] [--skip-changelog] [--skip-dependency] [--skip-documentation] [--skip-publish] [--skip-validation] [--version=<value>]
```

For example:

```bash
pdk release --force 

pdk release --skip-publish
```

|Argument|Description|Values|Default|
|--------|-----------|------|-------|
|`--file`|Provides a path to the built module to push to the Forge.|File system path.|This option can only be used when `--skip-build` is also used. Defaults to `pkg/<module version>.tar.gz`|
|`--force`|Releases the module automatically without prompts.| |When specified, no prompts are given to the user. This automatically set when in Continuous Integration (CI) environments such as Travis CI or Appveyor CI.|
|`--forge-token`|Sets Forge API token. See [Forge API reference](https://forgeapi.puppet.com/#section/Authentication/ApiKeyAuth) for information about how to generate a token.|Forge API token.|Required when publishing modules to the Forge.|
|`--forge-upload-url`|Sets Forge upload URL path.|Forge API releases endpoint.|Forge API - `https://forgeapi.puppetlabs.com/v3/releases`|
|`--skip-build`|Skips building the module.|None.|If not specified, builds the module package.|
|`--skip-changelog`|Skips the automatic Changelog generation.|None.|If not specified, generates Changelog.|
|`--skip-dependency`|Skips the module dependency check.|None.|If not specified, checks module dependencies.|
|`--skip-documentation`|Skips the documentation update.|None.|If not specified, updates documentation.|
|`--skip-publish`|Skips publishing the module to the Forge.|None.|If not specified, publishes module to the Forge.|
|`--skip-validation`|Skips the module validation check.|None.|If not specified, validates module.|
|`--version`|Updates the module to the specified version prior to release.|A semantic version number. For example, 1.2.0.|When not specified, the new version is computed from the Changelog when possible.|

## `pdk release prep` command

Prepares a module to be built for the Forge.

> **Note:** This is an experimental command as it is not fully implemented and
might change in the future.

Usage:

```bash
pdk release  prep [--force] [--skip-changelog] [--skip-dependency] [--skip-documentation] [--skip-validation]
```

For example:

```bash
pdk release prep --force 

pdk release prep --skip-documentation
```

|Argument|Description|Values|Default|
|--------|-----------|------|-------|
|`--force`|Prepares the module automatically without prompts.|None.|When specified, no prompts are given to the user. This automatically set when in Continuous Integration (CI) environments such as Travis CI or Appveyor CI.|
|`--skip-changelog`|Skips the automatic Changelog generation.|None.|If not specified, generates Changelog.|
|`--skip-dependency`|Skips the module dependency check.|None.|If not specified, checks module dependencies.|
|`--skip-documentation`|Skips the documentation update.|None.|If not specified, updates documentation.|
|`--skip-publish`|Skips publishing the module to the Forge.|None.|If not specified, publishes module to the Forge.|
|`--skip-validation`|Skips the module validation check.|None.|If not specified, validates module.|
|`--version`|Updates the module to the specified version prior to release.|A semantic version number. For example, 1.2.0.|When not specified, the new version is computed from the Changelog when possible.|

## `pdk release publish` command

Publishes an already built module to the Forge.

> **Note:** This is an experimental command, which is not fully implemented and
might change in the future.

Usage:

```bash
pdk release [--force] [--forge-token=<value>] [--forge-upload-url=<value>]
```

For example:

```bash
pdk release publish --force 

pdk release --forge-token=abc123
```

|Argument|Description|Values|Default|
|--------|-----------|------|-------|
|`--force`|Releases the module automatically without prompts.|None.|When specified, no prompts are given to the user. This automatically set when in Continuous Integration (CI) environments such as Travis CI or Appveyor CI.|
|`--forge-token`|Sets Forge API token. See [Forge API reference](https://forgeapi.puppet.com/#section/Authentication/ApiKeyAuth) for information about how to generate a token.|Forge API token.|Required when publishing modules to the Forge.|
|`--forge-upload-url`|Sets Forge upload URL path.|Forge API releases endpoint.|Forge API - `https://forgeapi.puppetlabs.com/v3/releases`|

## `pdk test unit` command

Runs unit tests. Errors are displayed to the console and reported in the target
file, if specified. The exit code is non-zero when errors occur.

Usage:

Within the module directory:

```bash
pdk test unit --list

pdk test unit [--tests=<TEST_LIST>] [--format=<FORMAT>[:<TARGET_FILE>]] [--puppet-version=<VERSION>]

```

For example:

```bash
pdk test unit --tests=test1,test2,test3 --puppet-version=5
```

To learn more, see the [validating and testing modules](pdk_testing.md) topic.
For step-by-step instructions, see the [unit test a module](pdk_testing.md#unit-test-a-module)
topic.

|Argument|Description|Value|Default|
|--------|-----------|-----|-------|
|`--clean-fixtures`, `-c`|Cleans test fixtures, removing them from the directory and downloading them again the next time you run `pdk test unit`.|None.|If not specified, does not clean test fixtures.|
|`--format=<FORMAT>[:<TARGET_FILE>]`|Specifies the format of the output. Optionally, you can specify a target file for the given output format, such as `--format=junit:report.xml` . You can specify multiple `--format` options if each has a distinct output target. To output to standard output or standard error, specify `stdout` or `stderr` as the target value.|<ul><li>`junit` (JUnit XML)</li><li>`text` (plain text)</li></ul>|If not specified, does not output to a file, but displays errors in the terminal.|
|`--list`|Displays a list of unit tests and their descriptions. Using this option lists the tests without running them.|No value. Optional `--verbose` or `-v` flag displays more information.|No default.|
|`--puppet-dev`|When specified, PDK runs unit tests against the current Puppet source from GitHub. To use this option, you must have network access to https://github.com. You cannot specify `--puppet-dev` together with the `--puppet-version=` options.|None.|If not specified, PDK runs unit tests against default values or those specified by `--puppet-version`.|
|`--puppet-version`|Specifies the Puppet gem version to run unit tests against.|A string indicating the Puppet version to test against, such as "5.4.2" or "5.5".|If not specified, tests against the most recent compatible Puppet version included in the PDK package.|
|`--tests=<TEST_LIST>`|A comma-separated list of tests to run. Use this during development to pinpoint a single failing test.|See the `--list` output for available values.|No default.|
|`--verbose`|When specified, PDK outputs a single line description for each test as the test is executed. This option uses the RSpec `documentation` format. For more information, see [RSpec Core Formatters](https://rubydoc.info/gems/rspec-core/RSpec/Core/Formatters).|None.|None.|

## `pdk update` command

Update a PDK compatible module with any changes made to the module template.

Usage:

Within the module directory:

```bash
pdk update [--force] [--noop]
```

For example: `pdk update`

To learn more, see [updating the module with template
changes](pdk_updating_modules.md). For step-by-step instructions, see the
[update a module](customizing_module_config.md#update-a-module) topic.

|Argument|Description|Values|Default|
|--------|-----------|------|-------|
|`--force`|Update the module without prompts. Cannot be used together with `--noop`.|None.|If not specified, PDK prompts for user input.|
|`--noop`|Shows what changes PDK would make, but does not actually make those changes. Cannot be used together with `--force`.|None.|If not specified, PDK prompts for user input and makes changes to the module on confirmation. |
|`--template-ref=<VALUE>`|Specifies the reference to use for the specified template for this module.|A template branch name, tag name, or commit SHA for the specified template.|If you have specified a custom template, previously updated your module to a non-default `--template-ref` value, this defaults to the value previously specified in your module metadata. Otherwise, defaults to the currently installed PDK version (on PDK native package installations) or "main" (on PDK gem installations).|

## `pdk validate` command

Runs all static validations. Any errors are reported to the console in the
format requested. The exit code is non-zero when errors occur.

Usage:

Within the module directory:

```bash
pdk validate --list

pdk validate [--format=<FORMAT>][:<TARGET_FILE>]] [<VALIDATIONS>] [<TARGETS>*] [--auto-correct] [--parallel] [--puppet-version=<VERSION>]

```

For example:

```bash
pdk validate --format=text:report.xml --auto-correct --parallel
```

To learn more, see [validating and testing modules](pdk_testing.md).
For step-by-step instructions, see the [validate a module](pdk_testing.md#validate-a-module)
topic.

|Argument|Description|Values|Default|
|--------|-----------|------|-------|
|`--auto-correct, -a`|Automatically corrects some common code style problems.|None.|Off.|
|`--format=<FORMAT>[:<TARGET_FILE>]`|Specifies the format of the output. Optionally, you can specify a target file for the given output format, such as `--format=junit:report.xml` . You can specify multiple `--format` options if each has a distinct output target. To output to standard output or standard error, specify `stdout` or `stderr` as the target value.|<ul><li>`junit` (JUnit XML)</li><li>`text` (plain text)</li></ul>|No default.|
|`--list`|Displays a list of available validations and their descriptions. Using this option lists the tests without running them.|None.|No default.|
|`--parallel`|Runs all validations simultaneously, using multiple threads.|None.|If not specified, validations are run in succession on a single thread.|
|`--puppet-dev`|When specified, PDK validates against the current Puppet source from GitHub. To use this option, you must have network access to https://github.com. You cannot specify `--puppet-dev` together with the `--puppet-version=` options.|None.|If not specified, PDK validates against default values or those specified by `--puppet-version`.|
|`--puppet-version`|Specifies the Puppet gem version to run validations against.|A string indicating the Puppet version to validate against, such as "5.4.2" or "5.5".|If not specified, validates against the most recent compatible Puppet version included in the PDK package.|
|`<TARGETS>`|A list of directories or individual files to validate. Validations which are not applicable to individual files will be skipped for those files.|A space-separated list of directories or files.|Validates all available directories and files.|
|`<VALIDATIONS>`|A comma-separated list of validations to run or `all` for all validations. In PowerShell, this list must be enclosed in single quotes, such as `pdk validate 'puppet,metadata'`|See the `--list`output for a list of available validations.|`all`|
