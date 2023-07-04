# PDK troubleshooting

If you are encountering trouble with PDK, check for these common issues. 

## PDK not in ZShell PATH on Mac OS X

With ZShell on Mac OS X, PDK is not automatically added to the PATH. To fix
this, add the PATH by adding the line `eval (/usr/libexec/path_helper -s)` to
the ZShell resource file (`~/.zshrc`).

