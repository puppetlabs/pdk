# PDK known issues

## Upgrading the pdk over-writes the pdk's "cert.pem"

Upgrading the pdk from one version to another, e.g., going from `3.0.0.0` to `3.2.0.1`, will over-write the existing `/opt/puppetlabs/pdk/ssl/cert.pem` on linux or `C:\Program Files\Puppet Labs\DevelopmentKit\ssl\cert.pem` on windows.

For example, if you have customized the `cert.pem` to trust a self-hosted git repository server like `git.self.hosted`, then after the PDK upgrade an error may appear during PDK usage like `fatal: unable to access 'https://git.self.hosted/companyxyz/mymodule.git/': SSL certificate problem: self signed certificate`.

For more information on how to correct this known issue see the [PDK Troubleshooting](pdk_troubleshooting.md#pdk-failing-to-pull-from-custom-git-server) section.

## PDK v3.0.1 Windows Cert expired

This issue was resolved and shipped in PDK v3.1.0, if you are seeing an issue in relation to an expired cert, please upgrade the PDK.  
