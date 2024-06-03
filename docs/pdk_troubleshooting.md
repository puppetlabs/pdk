# PDK troubleshooting

If you are encountering trouble with PDK, check for these common issues.

## PDK not in ZShell PATH on Mac OS X

With ZShell on Mac OS X, PDK is not automatically added to the PATH. To fix
this, add the PATH by adding the line `eval (/usr/libexec/path_helper -s)` to
the ZShell resource file (`~/.zshrc`).

## PDK failing to pull from custom git server

If a `fatal: unable to access...SSL certificate problem: self signed certificate` error occurs during PDK usage, it indicates that the PDK is trying to download a module from a source that isn't trusted. For example, given a `.fixtures.yml` that references an untrusted self-hosted git repository server `git.self.hosted`

```yaml
# .fixtures.yml
---
fixtures:
  forge_modules:
    nginx: "puppet/nginx"
  repositories:
    mymodule: 'https://git.self.hosted/companyxyz/mymodule.git'
```

then running `pdk test unit` will throw an error something like:

```bash
root@seattle:~/modules/tester# pdk test unit
pdk (INFO): Using Ruby 3.2.2
pdk (INFO): Using Puppet 8.1.0
[✖] Preparing to run the unit tests.
[✔] Cleaning up after running unit tests.
pdk (ERROR): The spec_prep rake task failed with the following error(s):

Cloning into 'spec/fixtures/modules/mymodule'...
fatal: unable to access 'https://git.self.hosted/companyxyz/mymodule.git/': SSL certificate problem: self signed certificate
#<Thread:0x00007ffff9b2e138 /opt/puppetlabs/pdk/share/cache/ruby/3.2.0/gems/logging-2.3.1/lib/logging/diagnostic_context.rb:471 run> terminated with exception (report_on_exception is true):
...
...
```

To resolve this issue, first create a backup of the existing PDK certificates file, which lives `/opt/puppetlabs/pdk/ssl/cert.pem` on linux machines and `C:\Program Files\Puppet Labs\DevelopmentKit\ssl\cert.pem` on windows.  

Then do the following

* Obtain the chain of trust certificates from the self-hosted server.  For example, `printf '' | openssl s_client -connect git.self.hosted:443 -showcerts` will return metadata including the trust certificates for the `git.self.hosted:443` server.
* Append the trust certificates to the end of the `cert.pem` ensuring the pdk "trusts" the new self-hosted git server.

**NOTE:** There is a known issue [Upgrading the pdk over-writes the pdk's cert.pem](pdk_known_issues.md#upgrading-the-pdk-over-writes-the-pdks-certpem).  Therefore, any custom certificates will need to be added again after upgrading the pdk.
