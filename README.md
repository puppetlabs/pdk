# pdk

[![Code Owners](https://img.shields.io/badge/owners-DevX--team-blue)](https://github.com/puppetlabs/pdk/blob/main/CODEOWNERS)
[![ci](https://github.com/puppetlabs/pdk/actions/workflows/ci.yml/badge.svg)](https://github.com/puppetlabs/pdk/actions/workflows/ci.yml) 
[![Gem Version](https://badge.fury.io/rb/pdk.svg)](https://badge.fury.io/rb/pdk)

* [Installation](#installation)
* [Basic usage](#basic-usage)
* [Experimental features](#experimental-features)
* [Module compatibility](#module-compatibility)
* [Contributing](#contributing)
* [Contact Information](#contact-information)

The Puppet Development Kit (PDK) includes key Puppet code development and testing tools for Linux, Windows, and OS X workstations, so you can install one package with the tools you need to create and validate new modules.

PDK includes testing tools, a complete module skeleton, and command line tools to help you create, validate, and run tests on Puppet modules. PDK also includes all dependencies needed for its use.

PDK includes the following tools:

|Tool|Description|Owned by Puppet|
|----|-----------|---------------|
|facterdb|A gem that contains facts for Operating Systems.| N |
|metadata-json-lint|Validates and lints `metadata.json` files in modules against Puppet module metadata style guidelines.| N |
|pdk|Tool to generate and test modules and module content, such as classes, from the command line.| Y |
|puppet-lint|Checks your Puppet code against the recommendations in the Puppet language style guide.| Y |
|puppet-syntax|Checks for correct syntax in Puppet manifests, templates, and Hiera YAML.| N |
|puppetlabs_spec_helper|Provides classes, methods, and Rake tasks to help with spec testing Puppet code.| Y |
|rspec-puppet|Tests the behavior of Puppet when it compiles your manifests into a catalog of Puppet resources.| Y |
|rspec-puppet-facts|Adds support for running `rspec-puppet` tests against the facts for your supported operating systems.| N |


## Installation

Download and install the newest package matching your platform from the [download](https://puppet.com/download-puppet-development-kit) page. If you are using Windows, remember to close any open PowerShell windows.

For complete installation information, see the [PDK documentation](https://puppet.com/docs/pdk/latest/pdk_install.html).

## Basic usage

PDK can generate modules and classes, validate module metadata, style, and syntax, and run unit tests. This README contains very basic usage information---for complete usage information, see the [PDK documentation](https://puppet.com/docs/pdk/latest/pdk_install.html).

### Generate a module

Generates the basic components of a module and set up an infrastructure for testing it with PDK.

1. Run the `pdk new module` command, specifying the name of the new module:

```
pdk new module my_module
```

This command asks a series of metadata questions and then generates the basic components of a new module.

### Generate a class

To generate a class in your module, use the `pdk new class` command, specifying the name of your new class. To generate the main class of the module, which is defined in an `init.pp` file, give the class the same name as the module.

1. From the command line, in your module's directory, run:
```
pdk new class class_name
```

PDK creates the new class manifest and a test file (as `class_name_spec.rb`) in your module's `/spec/classes` directory.

### Generate a defined type

To generate a defined type in your module, use the `pdk new defined_type` command, specifying the name of your new defined type.

1. From the command line, in your module's directory, run:
```
pdk new defined_type defined_type_name
```

PDK creates the new defined\_type manifest and a test file (as `defined_type_name_spec.rb`) in your module's `/spec/defines` directory.

### Generate a task

To generate a task in your module, use the `pdk new task` command, specifying the name of your new task.

1. From the command line, in your module's directory, run:
```
pdk new task task_name
```

PDK creates the new task file and metadata.

### Validating a module

PDK can validate the well-formedness of the module and style and syntax of its files.

1. In the module's directory, run:

```
pdk validate
```

This command validates the metadata, Puppet code syntax and style, and Ruby syntax and style for the entire module.

### Run unit tests

PDK's [default template](https://github.com/puppetlabs/pdk-templates) sets up [rspec](http://rspec.info/) for Ruby-level unit testing, and [rspec-puppet](https://github.com/puppetlabs/rspec-puppet/) for catalog-level unit testing.

In the module's directory, run unit tests with:

```
pdk test unit
```

This command runs all available unit tests.

## Module Compatibility

**PDK Version Compatibility:** Modules created with PDK validate against and run on all Puppet and Ruby version combinations currently under maintenance (see https://docs.puppet.com/puppet/latest/about_agent.html and https://puppet.com/misc/puppet-enterprise-lifecycle)

## Contributing

PDK encourages community contributions. See the [CONTRIBUTING.md](CONTRIBUTING.md) file for development notes.

## License

This codebase is licensed under Apache 2.0. However, the open source dependencies included in this codebase might be subject to other software licenses such as AGPL, GPL2.0, and MIT.

## Contact Information

* [For reporting bugs](https://github.com/puppetlabs/pdk/blob/main/CONTRIBUTING.md#reporting-bugs)
* To contact us with questions, [join the Puppet Community on Slack](https://slack.puppet.com/)
