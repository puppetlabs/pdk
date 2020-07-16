# PDK troubleshooting

If you are encountering trouble with PDK, check for these common issues. 

## Windows: Execution policy restrictions

In some Windows installations, the default execution policy restrictions
prohibit `pdk` commands.

To fix this issue, set your script execution policy to at least `RemoteSigned`
by running `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`

Alternatively, you can change the `Scope` parameter of the `ExecutionPolicy` to
the current session by running `Set-ExecutionPolicy -ExecutionPolicy
RemoteSigned -Scope CurrentUser`

For more information about PowerShell execution policies or how to change them,
see Microsoft documentation about
[Execution_Policies](http://go.microsoft.com/fwlink/?LinkID=135170) and how to
set [execution
policy](https://msdn.microsoft.com/en-us/powershell/reference/5.1/microsoft.powershell.security/set-executionpolicy).

> **Note:** Windows versions older than Windows 10 might not recognize the `pdk`
command. If you are running an older version of Windows, you might need to
update your PowerShell prior to using PDK.

## PDK not in ZShell PATH on Mac OS X

With ZShell on Mac OS X, PDK is not automatically added to the PATH. To fix
this, add the PATH by adding the line `eval (/usr/libexec/path_helper -s)` to
the ZShell resource file (`~/.zshrc`).

