# pdk [![Build Status](https://travis-ci.org/puppetlabs/pdk.svg?branch=master)](https://travis-ci.org/puppetlabs/pdk) [![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/x70e2fqllbaootpd?svg=true)](https://ci.appveyor.com/project/puppetlabs/pdk) [![Coverage Status](https://coveralls.io/repos/github/puppetlabs/pdk/badge.svg?branch=master)](https://coveralls.io/github/puppetlabs/pdk?branch=master)

* [Installation](#installation)
* [Basic usage](#basic-usage)
* [Experimental features](#experimental-features)
* [Module compatibility](#module-compatibility)
* [Contributing](#contributing)
* [Contact Information](#contact-information)

The Puppet Development Kit (PDK) includes key Puppet code development and testing tools for Linux, Windows, and OS X workstations, so you can install one package with the tools you need to create and validate new modules.

PDK includes testing tools, a complete module skeleton, and command line tools to help you create, validate, and run tests on Puppet modules. PDK also includes all dependencies needed for its use.

PDK includes the following tools:

Tool   | Description
----------------|-------------------------
metadata-json-lint | Validates and lints `metadata.json` files in modules against  Puppet's module metadatastyle guidelines.
pdk | Command line tool for generating and testing modules
puppet-lint | Checks your Puppet code against the recommendations in the Puppet Language style guide.
puppet-syntax | Checks for correct syntax in Puppet manifests, templates, and Hiera YAML.
puppetlabs_spec_helper | Provides classes, methods, and Rake tasks to help with spec testing Puppet code.
rspec-puppet | Tests the behavior of Puppet when it compiles your manifests into a catalog of Puppet resources.
rspec-puppet-facts | Adds support for running rspec-puppet tests against the facts for your supported operating systems.


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

PDK's default template sets up [rspec](http://rspec.info/) for Ruby-level unit testing, and [rspec-puppet](https://github.com/rodjek/rspec-puppet/) for catalog-level unit testing.

In the module's directory, run unit tests with:

```
pdk test unit
```

This command runs all available unit tests.

### Convert an existing module

To convert an existing module to be managed by the PDK you can first decide on which template to use. This by default is set as the [pdk-module-template](https://github.com/puppetlabs/pdk-templates), however you are welcome to define and use your own template. You can do this by passing a parameter to the pdk convert command:
```
pdk convert --template-url my/template/location
```

1. To start this process with the default module template:

```
pdk convert
```

This command will then proceed to output a short summary based on converting your module to the pdk template, informing you which files will be added and modified.

You will then be prompted with the choice to apply the changes or to abandon the process. Please note that although some of the changes can be automatically fixed, some may need manual intervention.

Regardless of your decision, a full report generated by the command will be put in conver_report.txt for review. (Please note this file will be overwritten each time you run the command to reflect the current state.)

If you choose to apply changes your module will absorb the changes brought in by the template and become PDK compatible.

There are several parameters that can be used for this command:

```
pdk convert --noop
```
Use 'noop' to run a no-op or dry-run mode. This is useful for seeing what changes Puppet will make without actually executing the changes. 

```
pdk convert --force
```
Use 'force' to run the convert command and to automatically apply the changes.

Please Note: This command can be potentially destructive as it will manipulate your files. Ensure you back up any of your work beforehand, or commit to a source control tool.

#### Additional Configuration for Convert

When using PDK you may want to add your own customizations that may not fall in line with the template, and for this we have provided the ability to use a .sync.yml file to add any extra configuration that is needed.

This configuration is absorbed by PDK and applied to the relevant files at rendering. So as long as you have a well formatted .sync.yml and it’s located in the top directory of the module the changes described in it will be applied when you run `pdk convert` command.

For example, if you wanted to modify the puppet lint configuration, add additional gems used as part of the release process or add new tasks to the Rakefile, you can define these all within .sync.yml.


## Experimental features

### `pdk bundle` command

This command executes arbitrary commands in a bundler context within the module you're currently working on. Arguments to this command are passed straight through to bundler. This command is experimental  and can lead to errors that can't be resolved by the pdk itself.

Note that for most uses, you must use the `--` to separate bundler options from pdk options. Compare the following two commands:

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

#### Known issues


Note that for PowerShell the `--` must be escaped using a backtick ( <code>`-- </code> ) or the shell parses it and strips it out of the command. See [PDK-408](https://tickets.puppet.com/browse/PDK-408) for details.

## Module Compatibility

**PDK Version Compatibility:** Modules created with PDK version validate against and run on all Puppet and Ruby version combinations currently under maintenance (see https://docs.puppet.com/puppet/latest/about_agent.html and https://puppet.com/misc/puppet-enterprise-lifecycle)

## Contributing

PDK encourages community contributions. See the [CONTRIBUTING.md](CONTRIBUTING.md) file for development notes.

## Contact Information

To contact us with questions: [pdk-maintainers@puppet.com](mailto:pdk-maintainers@puppet.com)
