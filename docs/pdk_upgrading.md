# Upgrading PDK

Update to the latest version of PDK to get new features, improvements, and bug
fixes.

Upgrade PDK using the same method you used to originally install it. See the PDK
[installation](pdk_install.md) instructions for your platform for details.
Then, update your modules to integrate any module template changes.

## Update a module with template changes

Update your module to keep it current with PDK or custom module template
changes. 

> **Before you begin**
> Ensure that the module you are updating is compatible with PDK version 1.3.0 or
later. If the module was created with versions of PDK earlier than 1.3.0,
convert the module to the current template with the pdk convert command. See [converting modules](pdk_converting_modules.md) for more
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

