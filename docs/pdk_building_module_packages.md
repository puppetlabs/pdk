# Building module packages

Before you can upload and publish your module to the Forge, build an uploadable
module package.

The `pdk build` command performs a series of checks on your module and builds a
`tar.gz` package so that you can upload your module to the Forge. To learn more
about publishing your module to the Forge, see the documentation about
[publishing your
module](https://puppet.com/docs/puppet/4.9/modules_publishing.html#removing-symlinks-from-your-module). 

When you run the `pdk build` command, PDK checks your module metadata, looks for
any symlinks, and excludes from the package any files listed in the `.gitignore`
or `.pdkignore` files. If PDK finds any issues with metadata or symlinks, it
prompts you to fix these issues.

By default, the `.pdkignore` file contains a list of commonly ignored files,
such as temporary files. This file is located in the module's main directory. To
add or remove files to this list, define them in the module's `.sync.yml` file
and run `pdk update` on your module.

PDK prompts you for confirmation before building the package. It writes module
packages to the module's `pkg` directory, but you can specify a different
directory if you prefer. PDK names module packages with the convention
`forgeusername-modulename-version.tar.gz`.

## Build a module

Build a module package with the `pdk build` command so that you can upload your
module to the Forge.

1.  From the command line, change into the module's directory with `cd
    <MODULE_NAME>`

2.  Run `pdk build` and respond to any prompts.

    To change the behavior of the build command, add option flags to the
    command. For example, to create the package to a custom location, run `pdk
    build --target-dir=<PATH>` . For a complete list of command options and
    usage information, see the PDK [command reference](pdk_reference.md).


**Result:**

PDK builds a package with the naming convention
`forgeusername-modulename-version.tar.gz` to the `pkg` directory of the module.

### What to do next:

You can now upload your module to the Forge.

