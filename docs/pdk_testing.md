# Validating and testing modules

Puppet Development Kit (PDK) provides tools to help you run unit tests on your
module and validate your module's metadata, syntax, and style.

By default, the PDK module template includes tools that can:

-   Validate the `metadata.json` file.

-   Validate Puppet syntax.

-   Validate Puppet code style.

-   Validate Ruby code style.

-   Run unit tests.


If you are working behind a proxy, before you begin, ensure that you've added
the correct environment variables. See [Setting up PDK behind a
proxy](pdk_install.md#setting-up-pdk-behind-a-proxy) for details.

To ensure that your module works with Puppet, validate and unit test your
modules against specific versions of Puppet and Puppet Enterprise. This allows
you to find and fix module issues before you upgrade.

With command line options, you can specify major or minor versions, such as
Puppet 5 or PE 2017.3.2. When you specify a major version, PDK tests against the
most recent available release of the major version. PDK reports which PE or
Puppet version it is running checks against. For usage instructions and
examples, see the unit testing and validation topics below.

You can validate or test against any version of Puppet or PE that is currently
under maintenance. See [open source
Puppet](https://docs.puppet.com/puppet/latest/about_agent.html) and [Puppet
Enterprise](https://www.puppet.com/products/puppet-enterprise/support-lifecycle)
lifecycle pages for details.

## Validating modules

Ensure that your module contains correct syntax and style by validating your
module. PDK includes validations for module metadata, Puppet code syntax and
style, and Ruby code syntax and style. 

When you run validations, PDK output tells you which validations it is running
and notifies you of any errors or warnings it finds for each type of validation:

-   Syntax validations verify that your module code syntax works with specific
    versions of Puppet. If your module has syntax errors, correct them to ensure
    that your module works correctly.

-   Code style validations verify that your code follows style guidelines and
    best practices. Such errors do not prevent your module from functioning;
    however, fixing them makes your code readable and maintainable.

-   Metadata validations verify that module metadata is present and properly
    formatted. PDK unit testing relies on metadata for important information,
    such as operating system compatibility. Some of this information is also
    required if you publish your module to the Forge. Correct metadata errors to
    provide this information.


By default, PDK runs all available validations. You can customize PDK validation
with command line options. For example, you can pass options to have PDK
automatically correct some common code style problems, to validate only specific
directories or files, or to run only certain types of validation, such as
metadata or Puppet code.

You can output module validation results to a file in either JUnit or text
format. You can specify multiple output formats and targets in the same command,
as long as each target is unique.

For detailed information about module validations, see:

-   [Puppet Lint](http://puppet-lint.com/) style validation.

-   The [Puppet language style
    guide](https://puppet.com/docs/puppet/latest/style_guide.html).

-   [Rubocop](https://docs.rubocop.org) Ruby style validation.

-   [metadata-json-lint](https://github.com/voxpupuli/metadata-json-lint)
    metadata validation.

-   [Module
    metadata](https://puppet.com/docs/puppet/latest/modules_metadata.html).


## Validate a module

By default, the `validate` command runs metadata validation first, then Puppet
validation, then Ruby validation. Optionally, you can validate only certain
files or directories, run a specific type of validations, such as metadata or
Puppet validation, or run all validations simultaneously. Additionally, you can
send your validation output to a file in either JUnit or text format.

1.  From the command line, change into the module's directory with `cd
    <MODULE_NAME>`

2.  Run all validations by running `pdk validate` .

    To change validation behavior, add option flags to the command. For example,
    to run all validations simultaneously on multiple threads, run:

    ```no-highlight
    pdk validate --parallel
    ```

    To validate against a specific version of Puppet or PE, add the
    `--puppet-version` option flag.

    For example. To validate against Puppet 5.5.12, run:

    ```no-highlight
    pdk validate --puppet-version 5.5.12
    ```

    For a complete list of command options and usage information, see the PDK
    command [reference](pdk_reference.md#).


### Ignoring files during module validation

There are times when certain files can be ignored when validating the contents of a Puppet module. PDK provides a configuration option to list sets of files to ignore when running any of the validators.

To configure PDK to ignore a file, use `pdk set config project.validate.ignore`.
The `project.validate.ignore` setting accepts multiple files. To add one or more files, run the command for each file or pattern you want to add.

For example, to ignore a file called `example.yaml` in the folder called `config`, you would run the following command:

```
pdk set config project.validate.ignore "config/example.yaml"
```

To add a wildcard, use a valid [Git ignore pattern](http://git-scm.com/docs/gitignore):

```
pdk set config project.validate.ignore "config/*.yaml"
```

## Unit testing modules

Create and run unit tests to verify that your Puppet code compiles on supported
operating systems and includes all declared resources in the catalog.

PDK runs your unit tests to ensure that your code compiles correctly and works
as you expect it to, but it cannot test changes to the managed system or
services.

PDK can create a basic unit test file that tests whether a manifest compiles to
the catalog on the operating systems specified in the module's `metadata.json`
file. PDK creates these unit test files when you:

-   Create a new class or defined type with the `pdk new class` or `pdk new
    defined_type` command.
-   Convert a module with the `--add-tests` option, such as `pdk convert
    --add-tests`.
-   Create new unit tests for an existing class or defined type with the `pdk
    new test --unit` command.

The unit test file is located in your module's `/spec/classes` (for classes) or
`/spec/defines` (for defined types) folder. In addition to testing whether your
code compiles, this file also serves as a template for writing further unit
tests to ensure that your code does what you expect it to do.

The `pdk test unit` command runs all of the tests in your module's `/spec/`
directory.

Test and validate your module before modifying or adding code, to verify that
you are starting out with clean code. As you develop your module, continue to
validate and unit test your code.

For more information about RSpec and writing unit tests, see:

-   [Writing puppetlabs-rspec tests](http://rspec-puppet.com/tutorial/)

-   [RSpec](http://rspec.info/)

-   [puppetlabs-rspec](https://github.com/puppetlabs/puppetlabs-rspec/)

-   [Puppet spec helper](https://github.com/puppetlabs/puppetlabs_spec_helper)


## Unit test a module

The `pdk test unit` command runs all the unit tests in your module.

> **Before you begin**
> Ensure that the `/spec/` directory contains the unit tests you want to run. Unit
tests generated by PDK test only whether the manifest compiles on the module's
supported operating systems, and you can write tests that test whether your code
correctly performs the functions you expect it to.

1.  From the command line, change into the module's directory with `cd
    <MODULE_NAME>`

2.  Run `pdk test unit`

    To change unit test behavior, add option flags to the command. For example,
    to run only certain unit tests, run:

    ```no-highlight
    pdk test unit --tests=<TEST1>,<TEST2>
    ```

    To unit test against a specific version of Puppet, add a version
    option flag.

    For example. To test against Puppet 5.5.12, run:

    ```no-highlight
    pdk test unit --puppet-version 5.5.12
    ```


**Result:**

PDK reports what Ruby and Puppet versions it is testing against, and after tests
are completed, test results. For a complete list of command options and usage
information, see the PDK command [reference](pdk_reference.md#).
