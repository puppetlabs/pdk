
**Note: this page is a draft in progress for a tech preview release and may differ from the final version.**

## Generating modules and classes with PDK

PDK generates the basic components of a module and sets up the basic infrastructure for testing it.

When you create a module, PDK asks you a series of questions that it uses to create metadata for your module.

Each question has a default response that PDK uses if you skip the question. The answers you provide to these questions are stored and used as the new defaults for subsequent module generations. Optionally, you can skip the interview step and use the default answers for all metadata.

* Your Puppet Forge username. If you don't have a Forge account, you can accept the default value for this question. If you create a Forge account later, edit the module metadata manually with the correct value. 
* Module version. We use and recommend semantic versioning for modules.
* The module author's name.
* The license under which your module is made available. This should be an identifier from [SPDX License List](https://spdx.org/licenses/).
* A one-sentence summary about your module.
* The URL to your module's source code repository, so that other users can contribute back to your module.
* The URL to a web site that offers full information about your module, if you have one..
* The URL to the public bug tracker for your module, if you have one.

After you generate a module, we suggest validating and testing the module _before_ you add classes or write new code in it. This allows you to verify that the module files and directories were correctly created.

PDK does not generate any classes at module creation. The `pdk new class` command creates a class manifest and a test template file for the class. When you run this command, PDK creates a class manifest and a test template file for the class. You can then write tests in this template to validate your class's behavior.

If your new class should take parameters, you can specify them, along with the parameter's data type and values, on the command line when you generate your class. You can provide any number of parameters on the command line.


## Generate a module with pdk

To generate a module with PDK's default template, use the `pdk new module` command.

Before you begin, ensure that you've installed the PDK package.

1. From the command line, run the `pdk new module` command, specifying the name of the module: `pdk new module module_name`
   
   Optionally, to skip the interview questions and generate the module with default values, use the `skip-interview` flag when you generate the module: `pdk new module module_name --skip-interview`

1. Respond to the PDK dialog questions in the terminal. Each question indicates the default value it will use if you just hit **Enter**.

   1. Forge username: Enter your Forge username, if you have a Forge account.
   2. Version: Enter the semantic version of your module, such as "0.1.0".
   3. Author: Enter the name of the module author.
   4. License: If you want to specify a license other than "Apache-2.0," specify that here, such as "MIT", or "proprietary".
   5. Description: Enter a one-sentence summary that helps other users understand what your module does.
   6. Source code repository: Enter the URL to your module's source code repository.
   7. Where others can learn more: If you have a website where users can learn more about your module, enter the URL.
   8. Where others can report issues: If you have a public bug tracker for your module, enter the URL.

1. If the metadata that PDK displays is correct, confirm with `Y` or **Enter** to generate the module. If it is incorrect, enter `n` to cancel and start over.

### Module contents

PDK generates a basic module, a directory with a specific structure. This module contains directories and files you need to start developing and testing your module.

To learn the basics of what a Puppet module includes, see the [Puppet docs on module fundamentals](https://docs.puppet.com/puppet/latest/modules_fundamentals.html).

PDK creates the following files and directories for your module:

Files and directories   | Description
----------------|-------------------------
Module directory | Directory with the same name as the module. Contains all of the module's files and directories.
Gemfile | File describing Ruby gem dependencies.
Rakefile | File listing tasks and dependencies.
`appveyor.yml` | File containing configuration for Appveyor CI integration.
`metadata.json` | File containing metadata for the module.
`/manifests` | Directory containing module manifests, each of which defines one class or defined type. PDK creates manifests only when you generate them with the `pdk new class` command.
`/spec` | Directory containing files and directories for spec testing.
`/spec/spec_helper.rb` | File containing containing any ERB or EPP templates.
`/spec/default_facts.yaml` | File containing default facts.
`/spec/classes` | Directory containing testing templates for any classes you generate with the `pdk new class` command.
`/templates` | Directory containing any ERB or EPP templates.

## Generate a new class

To generate a new class in your module, use the `pdk new class` command, specifying the name of your new class.

To generate the main class of the module, which is defined in an `init.pp` file, give the class the same name as the module.

1. From the command line, in your module's directory, run `pdk new class class_name`. Optionally, along with this command, specify any parameters with their data type and values.

   This example creates a new class and defines an `ensure` parameter, which is an Enum data type that accepts the values 'absent' and 'present'.

   ``` bash
   pdk new class class_name "ensure:Enum['absent','present']"
   ```

PDK creates the class in `module_name/manifests`. It also creates a test file (like `class_name_spec.rb`) in your module's `/spec/class` directory. This test file includes a basic template for writing your own unit tests.