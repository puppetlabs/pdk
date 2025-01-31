# PDK known issues

## PDK 3.4.0 - Issue with utilising bundled templates

We have recently begun seeing an issue with the default bundled templates on certain OSs, with the pdk failing to see them as valid as shown in the below error.

```
pdk (FATAL): Unable to find a valid module template to use.
```

Through investigation this has been shown to be a permssions issue regarding the `pdk-templates.git` file and unfortunately one that we have not been able to resolve in time for this release.

This error is most commonly found when creating a new module or attempting to update a module that was previously created from the default templates, within an airgapped environment. There are two possible solutions that we have found for this, with the first one being to grant the `pdk-templates.git` directory packaged with the pdk the permissions that it requires in order for it to be used, either by confirming the local user as the owner of the files through the `chown` command or by setting it as a safe directory via git.
Please be aware however that if using the `chown` command, you will have to reapply the fix between PDK versions.

```
sudo chown -R example.user /opt/puppetlabs/pdk/share/cache/pdk-templates.git
```
```
git config --global --add safe.directory /opt/puppetlabs/pdk/share/cache/pdk-templates.git
```

The other solution is to target a seperate template location a shown below:

 - When creating a new module simply target either the main branch or a specified tag on the Github pdk-templates fork, or if you are airgapped a local copy of it that you have cloned down. Once the first run has been made, the PDK should store your targeted templates location and automatically go to it moving forward, until such time as you target another or clear your .pdk cache.

```
pdk new module example --template-url=file:///Users/example.user/Github/pdk-templates --template-ref=3.4.0
```
```
pdk new module example --template-url=https://github.com/puppetlabs/pdk-templates --template-ref=main
```

- For existing modules that are targeting the default bundled templates, you will instead need to either run the `pdk convert` command as shown below to retarget them at a new template location, or manually alter the Modules metadata fields to target, though I would suggest using the convert command as a preference.

```
pdk convert --template-url=file:///Users/example.user/Github/pdk-templates --template-ref=3.4.0
```
```
pdk convert --template-url=https://github.com/puppetlabs/pdk-templates --template-ref=main
```

## PDK v3.3.0 requires puppet-modulebuilder

With the v3.3.0 release of the PDK, it has been updated to utilise the [puppet-modulebuilder](https://github.com/puppetlabs/puppet-modulebuilder) with the previously existing duplicated internal code having been removed. As such anyone who uses `PDK::Module::Build` in their setup will need to update their own code to do the same.

## Upgrading the pdk over-writes the pdk's "cert.pem"

Upgrading the pdk from one version to another, e.g., going from `3.0.0.0` to `3.2.0.1`, will over-write the existing `/opt/puppetlabs/pdk/ssl/cert.pem` on linux or `C:\Program Files\Puppet Labs\DevelopmentKit\ssl\cert.pem` on windows.

For example, if you have customized the `cert.pem` to trust a self-hosted git repository server like `git.self.hosted`, then after the PDK upgrade an error may appear during PDK usage like `fatal: unable to access 'https://git.self.hosted/companyxyz/mymodule.git/': SSL certificate problem: self signed certificate`.

For more information on how to correct this known issue see the [PDK Troubleshooting](pdk_troubleshooting.md#pdk-failing-to-pull-from-custom-git-server) section.

## PDK v3.0.1 Cert expired

This issue was resolved and shipped in PDK v3.1.0, if you are seeing an issue in relation to an expired cert, please upgrade the PDK.
