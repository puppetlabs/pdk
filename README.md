# pick 

The shortest path to better modules: Puppet Infrastructure Construction Kit

A CLI tool to facilitate easy, unified development workflows for puppet modules.

![pick logo using puppet dag shapes](docs/logo.png)

## Installation

Install it into your ruby installation as:

    $ gem install pick

## Usage

### Generate a new module

To start out using this tool set, generate a new module from the default template:

```
~/ $ pick generate module new_module
Generating new module 'new_module'...
+ ./new_module/metadata.json
[...]
```

This will lay out the basics of a new module, and initialise git for you. Some of the defaults will be guessed from your environment. Have a look at the `metadata.json` to make sure that the tool guessed right. The new module now contains all the infrastructure to use the other capabilities of `pick`.

#### Reference

```
pick generate module [--namespace=forge_user] [--github-user=github_user] [--template-url=git_url] [--license=spdx_identifier] [--vcs=vcs_provider] [--target-dir=directory] module_name
```

Generates a new module.

* `--namespace=forge_user`: Specify the forge username that will host this module. This is used globally to identify your contributions. Defaults to the local part of your mail address, if available.
* `--github-user=github_user`: Specify the [github](https://github.com) user that will host this module. Defaults to the namespace. If you don't use github to publish your module, you can ignore this.
* `--template-url=git_url`: Override the template to use for this module. If possible please contribute your improvements back to the default template at [puppetlabs/pick](https://github.com/puppetlabs/pick).
* `--license=spdx_identifier`: Specify the license this module will be written under. See https://spdx.org/licenses/ for a list of open source licenses, or use `propietary`. Defaults to `Apache-2.0`.
* `--vcs=vcs_provider`: Specify the version control driver. Currently supported are `git` and `none`. Defaults to `git`.
* `--target-dir=directory`: Specify where the new module should be located. Defaults to the current working directory. The module will be created in `directory/forge_user-modulen_name`. 
* `module_name`: Specify the name of your new module here. 

### Generate a new resource provider

To add code managing a specific resource that is not yet covered by puppet's basic resource types, or an existing module, create a new resource provider to fill the gap:

```
~/new_module $ pick generate provider new_provider String:content 'Enum[absent, present]:ensure'
Generating new resource provider `new_provider`...
+ ./lib/puppet/type/new_provider.rb
[...]
```

This will create all the files required to define a resource type, its provider, and the associated basic tests. In this example, the resource type will have a `ensure` property with the expected values, and a `String` property named `content`. Note the special quoting required to avoid confusing your shell when specifying more complex types.

#### Reference

```
pick generate provider [--template-url=git_url] provider_name [data_type:attribute_name]*
```

Generates a new resource provider.

* `--template-url=git_url`: Override the template to use for this module. If possible please contribute your improvements back to the default template at [puppetlabs/pick](https://github.com/puppetlabs/pick).
* `provider_name`: Specify the name of the new resource provider here.
* `data_type:attribute_name`: Specify a list of attributes with their expected data types.

### Running static tests

The default template provides a number of different tests that can improve confidence in the working of a module. Static tests are very quick to run, but only provide basic guarantees on the well-formedness of the module and syntax of its files. Run them like this:

```
~/new_module $ pick test static
Running static analysis on `new_module`:
* ruby syntax: OK!
* puppet syntax: OK!
[...]
```

#### Reference

```
pick test static [--list] [--tests=test_list] [--report-file=file_name] [--report-format=format]
```

Runs all "static" tests. Any errors are displayed to the console, and reported in the report-file, if requested. The exitcode is non-zero when errors occur.

* `--list`: Display a list of configured static tests and their descriptions. Using this option will skip running the tests.
* `--tests=test_list`: A comma separated list of tests to run. This can be used during development to pinpoint a single failing test. See the `--list` output for allowed values.
* `--report-file=file_name`: Specify a filename to write a report of the test results. Without a file name specified, no report will be created.
* `--report-format=format`: Specify the format of the report. Possible values are `junit`, or `text`. Defaults to `junit`.

### Running unit tests

The default template sets up [rspec](http://rspec.info/) for ruby-level unit testing, and [rspec-puppet](https://github.com/rodjek/rspec-puppet/) for catalog-level unit testing. To run all of them, use this command:

```
~/new_module $ pick test unit
Running unit tests on `new_module`:
[...]
Finished in 0.25554 seconds (files took 1.16 seconds to load)
72 examples, 0 failures
```

#### Reference

```
pick test unit [--list] [--tests=test_list] [--report-file=file_name] [--report-format=format] [rspec_options]
```






## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/puppetlabs/pick. Especially a better logo ;-)

