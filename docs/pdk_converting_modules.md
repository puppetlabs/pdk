# Converting modules

You can convert an existing module to a standardized PDK module with an
infrastructure for testing it. This allows you to use all the capabilities of
PDK with your module.

**Important:** Make sure your module is either backed up or under version
control because the `pdk convert` command modifies its files.

When you convert a module, PDK makes changes to it based on a default module
template. This is the same template that PDK uses when it creates a new module.
You can customize this template as needed; see the section about customizing
your module configuration for details.

If your module already has a `metadata.json` file, the metadata is merged with
the default metadata information from the module template. If the metadata does
not exist, PDK asks a series of interview questions to create the module's
metadata.

PDK then displays a summary of the files that will change during conversion and
prompts you to either continue or cancel the conversion. Either way, PDK
generates a detailed change report, `convert_report.txt`, in the top directory
of the module. This report is replaced by an updated version every time you run
the `convert` command.

## Files changed by `pdk convert`

During module conversion,  PDK might change or create the files listed below. It
does not change other files, such as Hiera data files. Before changing any
files, PDK reports what it will change, and you have the option to cancel
changes.

|File or directory|Description|
|-----------------|-----------|
|Module directory|Directory with the same name as the module. Contains all of the module's files and directories.|
|`appveyor.yml`|File containing configuration for Appveyor CI integration.|
|`Gemfile`|File describing Ruby gem dependencies.|
|`.gitignore`|File listing module files that Git should ignore.|
|`.gitlab-ci.yml`|File containing an example configuration for GitLab CI.|
|`.pdkignore`|File listing module files that PDK should ignore when building a module package for upload to the Forge.|
|`.pmtignore`|File listing module files that the `puppet module` command should ignore.|
|`Rakefile`|File containing configuration for the Ruby infrastructure. Used in CI and for backwards compatibility.|
|`.rspec`|File containing the default configuration for RSpec.|
|`.rubocop.yml`|File containing recommended settings for Ruby style checking.|
|`.travis.yml`|File containing configuration for cloud-based testing on Linux and Mac OS X. See [travis-ci](http://travis-ci.org/) for more information.|
|`.yardopts`|File containing configuration for [YARD](https://yardoc.org/) for source files, extra files, and formatting options that you want to use to generate your documentation.|

## Convert a module

To convert an existing module to a PDK compatible module, run the `pdk convert`
command.

1.  From the command line, change into the module's directory with `cd
    <MODULE_NAME>`

2.  Run the convert command: `pdk convert`

    Optionally, specify your own module template by adding the `--template-url`
    flag with the Git URL or local path to the template.

3.  If the existing module does not have a `metadata.json` file, respond to PDK
    metadata interview prompts to provide metadata information.

4.  Review the changes PDK is about to make and respond to the prompt to either
    continue or terminate the conversion. You can review a detailed change
    report in `convert_report.txt` in the module's root folder.


**Result:**

If you confirm the conversion, the changes outlined in the report are applied to
the module.

