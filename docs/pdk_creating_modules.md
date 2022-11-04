# Creating modules

PDK generates a complete new module with metadata, as well as creating classes,
defined types, and tasks in your module. It also sets up infrastructure for
validating and unit testing your module.

To create your module's metadata, PDK asks you a series of questions. Each
question has a default response that PDK uses if you skip the question. The
answers you provide to these questions are stored and used as the new defaults
for subsequent module creations. Optionally, you can skip the interview step and
use the default answers for all metadata. For details about editing the
`metadata.json` file, read about
module[metadata](https://puppet.com/docs/puppet/latest/modules_metadata.html).

PDK generates the empty module based on a default template, but you can specify
your own custom template with command line options. To see the complete default
module template, see the
[pdk-template](https://github.com/puppetlabs/pdk-templates) project on GitHub.

When you run the `pdk new module` command, it requests the following
information:

-   Your Puppet Forge user name. If you don't have a Forge account, you can
    accept the default value for this question. If you create an account later,
    edit the module metadata manually with the correct value.

-   Module version. We use and recommend semantic versioning for modules.

-   Your name.

-   The license under which your module is made available. Use an identifier
    from [SPDX License List](https://spdx.org/licenses).

-   A list of operating systems your module supports.

-   A one-sentence summary about your module.

-   The URL to your module's source code repository, so that other users can
    contribute back to your module.

-   The URL to a web site that offers full information about your module, if you
    have one.

-   The URL to the public bug tracker for your module, if you have one.


After you create a module, validate and test the module **before** you add
classes or write new code in it. This allows you to verify that the module files
and directories were correctly created.

After you have validated the module, you can create classes, defined types, and
tasks to your module by running `pdk` commands.

The new class and defined type commands create manifest and a test file
templates for the class or defined type.

The new task command creates task and task metadata templates. When you create a
task, PDK creates a task file in shell script \(`<TASK>.sh`\), but you can write
tasks in any language the target nodes will run. Be sure you use the correct
extension for the language you write tasks in. For more information about tasks,
see the [writing tasks](https://puppet.com/docs/bolt/latest/writing_tasks.html)
documentation.

## Create a module

To create a default module skeleton and testing templates, use the `pdk new
module` command.

> **Before you begin**
> Ensure that you've installed the PDK package.
> If you are running PDK behind a proxy, be sure you've added the correct
environment variables. See instructions for running PDK [behind a
proxy](pdk_install.md#setting-up-pdk-behind-a-proxy) for details.

1.  From the command line, run the new module command, specifying the name of
    the module: `pdk new module <MODULE_NAME>`

    Optionally, to omit the interview questions and create the module with
    default metadata values, add the `skip-interview` flag: `pdk new module
    <MODULE_NAME> --skip-interview`

2.  Respond to the dialog questions. Each question indicates the default value
    that it will use if you press Enter.

    1.  Forge username: Enter your Forge username, if you have an account.

    2.  Version: Enter the semantic version of your module, such as "0.1.0".

    3.  Author: Enter the name of the module author \(you or someone else
        responsible for the module's content\).

    4.  License: If you want to specify a license other than "Apache-2.0,"
        specify that here, such as "MIT", or "proprietary".

    5.  Operating System Support: Select which operating systems your module
        supports, choosing from the dialog menu.

    6.  Description: Enter a one-sentence summary that helps other users
        understand what your module does.

    7.  Source code repository: Enter the URL to your module's source code
        repository.

    8.  Where others can learn more: If you have a website where users can learn
        more about your module, enter the URL.

    9.  Where others can report issues: If you have a public bug tracker for
        your module, enter the URL.

3.  At the prompt, confirm or cancel module creation.


## Module contents

PDK creates a basic module skeleton with directories and templates to support
writing, validating, and testing Puppet code. 

|Files and directories|Description|
|---------------------|-----------|
|Module directory|Directory with the same name as the module. Contains all of the module's files and directories.|
|`appveyor.yml`|File containing configuration for Appveyor CI integration.|
|`CHANGELOG.md`|File in which you can document notable changes to this project.|
|`./files`|Directory containing static files, which managed nodes can download.|
|`.fixtures.yml`|File specifying where test dependencies are loaded from.|
|`Gemfile`|File describing Ruby gem dependencies.|
|`.gitattributes`|Recommended defaults for using Git.|
|`.gitignore`|File listing module files that Git should ignore.|
|`.gitlab-ci.yml`|File containing an example configuration for GitLab CI.|
|`./manifests`|Directory containing module manifests, each of which defines one class or defined type. PDK creates manifests when you create new classes or defined types with `pdk` commands.|
|`metadata.json`|File containing metadata for the module.|
|`.pdkignore`|File listing module files that PDK should ignore when building a module package for upload to the Forge.|
|`Rakefile`|File containing configuration for the Ruby infrastructure. Used in CI and for backwards compatibility.|
|`README.md`|File containing a README template for your module.|
|`.rspec`|File containing the default configuration for RSpec.|
|`.rubocop.yml`|File containing recommended settings for Ruby style checking.|
|`./spec`|Directory containing files and directories for unit testing.|
|`spec/default_facts.yml`|File specifying facts that are available to all tests.|
|`spec/spec_helper.rb`|Helper code to set up preconditions for unit tests.|
|`./spec/classes`|Directory containing testing templates for any classes you create with the `pdk new class` command.|
|`./tasks`|Directory containing task files and task metadata files for any tasks you create with the `pdk new task`command.|
|`./templates`|Directory containing any ERB or EPP templates. Required when building a module to upload to the Forge.|
|`.travis.yml`|File containing configuration for cloud-based testing on Linux and Mac OS X. See the [travis-ci](http://travis-ci.org/) docs for more information.|
|`.yardopts`|File containing the default configuration for Puppet Strings.|

## Create a class

To create a class in your module, use the `pdk new class` command.

The `pdk new class`command creates a class manifest file, with the naming
convention `class_name.pp`, and a test file.

1.  From the command line, in your module's directory, run `pdk new class
    <CLASS_NAME>`

    To create the module's main class, defined in an `init.pp` file, give the
    class the same name as the module: `pdk new class <MODULE_NAME>`.


**Result:**

PDK creates the new class manifest and a test template file
\(`class_name_spec.rb`\) in your module's `/spec/classes` directory. The test
template checks that your class compiles on all supported operating systems as
listed in the `metadata.json` file. You can then write additional tests in the
test file to validate your class's behavior.

## Create a defined type

To create a defined type for your module, use the `pdk new defined_type`
command.

The `pdk new defined_type` command creates a defined type manifest, with the
naming convention `defined_type_name.pp`, and a test file.

1.  From the command line, in your module's directory, run `pdk new defined_type
    <DEFINED_TYPE_NAME>`


**Result:**

PDK creates the new defined type manifest and a test file
\(`defined_type_spec.rb`\) in your module's `/spec/defines` directory. The test
template checks that your defined type compiles on all supported operating
systems as listed in the `metadata.json` file. You can then write additional
tests in the provided file to validate your defined type's behavior.

## Create a task

To create a task in your module, use the `pdk new task` command.

The `pdk new task`command creates a task file in shell script, with the naming
convention `task_name.sh`, and a task metadata file.

1.  From the command line, in your module's directory, run `pdk new task
    <TASK_NAME>`


**Result:**

PDK creates a task file, with the naming convention `task_name.sh` and a task
metadata file, `task_name.json` in the `./tasks` directory. Although the task
template is in shell script, you can write tasks in any language the target
nodes can run.

