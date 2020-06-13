# Updating modules with changes to the template

To keep your module's configuration current with changes to either the PDK
default template or your own custom template, use the `pdk update` command.

The `pdk update` function updates your module based on the template you used
when you created or converted your module. If there have been any changes to
that template PDK updates your module to incorporate them.

If you used a custom template, you can update whenever you know there is a
change in your template. If you didn't specify any custom template, you created
or converted your module using the default PDK template and can update when new
versions of PDK release.

When you run the `update` command, PDK displays a summary of the files that will
change during converstion and prompts you to either continue or cancel the
update. Either way, PDK generates a detailed change report, `update_report.txt`,
in the top directory of the module. This report is replaced by an updated
version every time you run the `update` command.

You can check for template changes by running `update` with the `--noop` option,
which runs the command in "no operation" mode. This option shows what changes
would be made, but doesn't actually make them.

**Important:** The default PDK template URL changed in PDK version 1.3.0. If you
created your module with a PDK version earlier than 1.3.0, update your PDK
version and run `pdk convert` on your old module to bring it up to date.

**Related information**  
- [Converting modules](pdk_converting_modules.md)

