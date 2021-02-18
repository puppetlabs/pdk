# Customizing your module configuration

PDK uses a default template to configure modules. You can customize this
configuration by specifying your own custom template or by customizing specific
template settings.

## Specifying a custom template

You can specify a custom template when creating a new module or when converting
an existing module.

Fork the default template from the
[pdk-template](https://github.com/puppetlabs/pdk-templates) project on GitHub,
and make any changes you need. If you must change the Gemfile or Rakefile, do so
carefully and test your changes. Major changes to the Gemfile or Rakefile of the
default template can cause errors with PDK.

Run either the `pdk convert` or the `pdk new module` command with the
`--template-url` option. For example:

```console
pdk convert --template-url https://github.com/myrepo/custom-module-template
```

## Customizing the default template

You can customize the default template on an existing module, whether you
created it with PDK or you are converting it to PDK. To customize a new module,
first create the module with PDK, and then apply any changes you want to the
template.

To customize the default template, create a `.sync.yml` file in your module.
This file must be in the top directory of the module and must be in a valid YAML
format. When you convert or update a module, PDK reads the `.sync.yml` file and
applies those changes to the relevant files.

In the `sync.yml` file, specify the file you want to manage with a top-level
key, such as `appveyor.yml`. Then add keys, indented two spaces, to change
configuration of that file. For example:

-   Setting `delete: true` deletes the named file, even if it is supplied
    through the module template.

-   Setting `unmanaged: true` ignores the the named file, even if it is supplied
    through the module template.

-   To see a complete updated list of `sync.yml` settings, see the
    [`pdk-template`
    README](https://github.com/puppetlabs/pdk-templates/blob/main/README.md).


For example, this `.sync.yml` file removes the `appveyor.yml` file from the
module. It also changes the Travis CI configuration to use Ruby version 2.1.9
and to run the command `bundle exec rake rubocop` as the test script in the
module.

```
appveyor.yml:
  delete: true
.travis.yml:
  extras:
  -rvm: 2.1.9
   script: bundle exec rake rubocop
```

## Update a module with template changes

Update your module to keep it current with PDK or custom module template
changes. 

> **Before you begin**
> Ensure that the module you are updating is compatible with PDK version 1.3.0 or
later. If the module was created with versions of PDK earlier than 1.3.0,
convert the module to the current template with the pdk convert command. See the
page about [converting modules](pdk_converting_modules.md) for more
information. 

The `pdk update` function updates your module based on the template you used
when you created or converted your module. If there have been any changes to
that template, PDK updates your module to incorporate them.

To check for template changes without making changes, run `update` with the
`--noop` option. This option runs the command in "no operation" mode, which
shows what changes would be made, but doesn't actually make them.
1.  From the command line, change into the module's directory with `cd
    <MODULE_NAME>`

2.  Run the update command: `pdk update`

3.  If any module metadata is missing, respond to PDK prompts to provide
    metadata information.

4.  Confirm the change summary PDK displays and either continue or cancel the
    update. 


**Result:**

Whether you confirm or cancel changes, PDK generates a detailed change report,
`update_report.txt`, in the top directory of the module. This report is updated
every time you run the `update` command.

If you confirm changes, PDK applies the reported changes to the module.

