
**Note: this page is a draft in progress for a tech preview release and may differ from the final version.**

## PDK reference

### `pdk new module` command

Generates a new module.

Usage:

```
pdk new module [--template-url=git_url] [--license=spdx_identifier] module_name [target_dir]
```

The `pdk new module` command accepts the following arguments and options. Arguments are optional unless otherwise specified.

Argument   | Description   | Values      | Default
----------------|:---------------:|:------------------:|-------------------------
`--template-url=git_url` | Overrides the template to use for this module. | A valid Git URL.    | No default.
`--license=spdx_identifier` | Specifies the license this module is written under. | See https://spdx.org/licenses/ for a list of open source licenses, or use `proprietary`.    | Apache-2.0
`--skip-interview` | Suppress interactive queries for initial values. Metadata will be generated with default values for all questions.| None    | No default.
`module_name` | **Required**. Specifies the name of the module being created. | A module name beginning with a lowercase letter and including only lowercase letters, digits, and underscores.    | No default.
`target_dir` | Specifies the directory that the new module will be created in. | A valid directory path   | Creates a directory with the given `module_name` inside the current directory.

### `pdk new class` command

Generates a new class and test templates for it in the current module.

Usage:

```
pdk new class [--template-url=git_url] <class_name> [parameter_name[:parameter_type]] [parameter_name[:parameter_type]] ...
```

For example:

```
cd my_module
pdk new class my_class "ensure:Enum['absent', 'present']" version:String
```

Argument   | Description   | Values      | Default
----------------|:---------------:|:------------------:|-------------------------
`--template-url` | Overrides the template to use when generating this class. | A valid URL to a class template. | Uses the template used to generate the module. If that template is not available, the default template at
[puppetlabs/pdk-module-template](https://github.com/puppetlabs/pdk-module-template)
is used.
`class_name` | **Required** The name of the class to generate. | A class name beginning with a lowercase letter and including only lowercase letters, digits, and underscores.    | No default.
`parameter_name[:parameter_type]` | Parameters for the generated class. Specify any number of parameters on the command line. | A valid parameter name, optionally with the parameter's data type.    | No default.

### `pdk validate` command

Runs all static validations. Any errors are reported to the console in the format requested. The exit code is non-zero when errors occur.

Usage:

```
pdk validate --list
```

```
pdk validate [--format=format[:target]] [validations] [targets*]
```

Argument   | Description   | Values      | Default
----------------|:---------------:|:------------------:|-------------------------
`--list` | Displays a list of available validations and their descriptions. Using this option lists the tests without running them. | None.    | No default.
`--format=format[:target]` | Specifies the format of the output. Optionally, you can specify a target file for the given output format with the syntax: `--format=junit:report.xml` Multiple `--format` options can be specified as long as they all have distinct output targets. | `junit` (JUnit XML), `text`(plain text)    | `text`
`validations` | Specifies a comma-separated list of validations to run (or `all`) | See the `--list` output for a list of available validations.    | `all`
`targets` | Specifies a list of directories or individual files to validate. Validations which are not applicable to individual files will be skipped for those files. | A space-separated list.    | Validates all available directories and files.

### `pdk test unit` command

Runs unit tests. Any errors are displayed to the console and reported in the report-file, if requested. The exitcode is non-zero when errors occur.

Usage:

```
pdk test unit [--list] [--tests=test_list] [--format=format[:target]] [runner_options]
```

Argument   | Description   | Values      | Default
----------------|:---------------:|:------------------:|-------------------------
`--list` | Displays a list of unit tests and their descriptions. Using this option lists the tests without running them. | None.    | No default.
`--tests=test_list` | A comma-separated list of tests to run. Use this during development to pinpoint a single failing test. | See the `--list` output for allowed values.    | No default.
`--format=format[:target]` | Specifies the format of the output. Optionally, you can specify a target file for the given output format with the syntax:`--format=junit:report.xml`. Multiple `--format` options can be specified as long as they all have distinct output targets. | `junit` (JUnit XML), `text`(plain text).     | `text`
