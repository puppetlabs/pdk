# Upgrading PDK

Update to the latest version of PDK to get new features, improvements, and bug
fixes.

Upgrade PDK using the same method you used to originally install it. See the PDK
[installation](pdk_install.md) instructions for your platform for details.
Then, update your modules to integrate any module template changes.

Note also that if you have added certificates for self-hosted git repositories to the pdk's `cert.pem` (`/opt/puppetlabs/pdk/ssl/cert.pem` on linux or `C:\Program Files\Puppet Labs\DevelopmentKit\ssl\cert.pem` on windows), then you'll need to re-append these certificates after the pdk upgrade. For more information see the known issue [Upgrading the pdk over-writes the pdk's `cert.pem`](pdk_known_issues.md#upgrading-the-pdk-over-writes-the-pdks-certpem).

## Upgrading to PDK 3.0.0

### Clear the local PDK cache

When PDK encounters a module with non standard dependencies (added by you or the module author),
it will cache gems in your user profile.

On Linux systems the cache can be found in `~/.pdk/cache` and on Windows systems it can be
found in `$ENV:USERPROFILE\AppData\Local\PDK\cache`.

Sometimes gems installed in the cache by older version of PDK can cause conflicts.
For that reason we recommend clearing the cache before you install PDK 3.0.0.

#### On Linux/MacOS

```bash
rm -rf ~/.pdk/cache
```

#### On Windows

```powershell
Remove-Item -Path $ENV:USERPROFILE\AppData\Local\PDK\cache -Recurse -Force
```

### Remove older versions of PDK (optional)

To be extra sure that you will have a smooth upgrade, you can remove your existing PDK installation.

Given that PDK can be installed through a variety of different methods, please consult the documentation
of the package provider for uninstallation steps.

### Remove the legacy PowerShell module (Windows only)

Versions of PDK prior to 3.0.0 used a PowerShell module to execute the application. This has now been removed as we
have transitioned to using a batch file as the entry point.

To avoid conflicts when running PDK you should ensure that the PowerShell module has been removed.
Additionally, if you will need to close and restart any open PowerShell sessions.

If it hasn't, it can easily be removed with a few simple steps:

#### Check if your new install still references the module

From a new PowerShell session, run the following command:

```powershell
Get-Command -name PDK
```

#### Check that the module has been removed from the $MODULEPATH

From a new PowerShell session run the following command:

```powershell
Get-ChildItem -Path 'C:\Program Files\WindowsPowerShell\Modules\'
```

If the `PuppetDevelopmentKit` module is listed in the output, it can safely be removed.

### Update your modules

PDK 3.0.0 removes support for Puppet 6 and Ruby 2.5.9. Before upgrading you should ensure that your modules
are compatible with later Puppet and Ruby releases.

Here are the versions of Puppet and Ruby that are included versions in PDK 3.0.0:

* Puppet 8 and Ruby 3.2.2
* Puppet 7 and Ruby 2.7.8

Once you are satisfied that your modules will support the versions listed above, you should ensure that your
modules also have the changes from the latest PDK templates.

To do this, simply run `pdk update` inside a module and follow the prompts.

### Troubleshooting issues after upgrading

#### `racc` errors with Ruby 2.7.8 and PDK 3.0.0

You may encounter the following error after upgrading to PDK 3.0.0

```bash
  bolt was resolved to 3.23.1, which depends on
    r10k was resolved to 3.15.4, which depends on
      gettext-setup was resolved to 1.1.0, which depends on
        gettext was resolved to 3.4.4, which depends on
          racc
```

This happens because newer versions of racc are native gems and therefore require some compilation on installation.

At this time, PDK cannot support all Gems with native extensions.

##### Resolution

To resolve the issue you can either:

* Run `pdk update`.
* Manually add the following requirement to your `.sync.yml` and run `pdk update`.

```yaml
  optional:
    ":development":
    - gem: racc
      version: '~> 1.4.0'
      condition: if Gem::Requirement.create(['>= 2.7.0', '< 3.0.0']).satisfied_by?(Gem::Version.new(RUBY_VERSION.dup))
```

#### `github_changelog_enerator` errors with Ruby 2.7.8 and PDK 3.0.0

You may encounter the following error after upgrading to PDK 3.0.0

```bash
   github_changelog_generator was resolved to 1.16.4, which depends on
    async-http-faraday was resolved to 0.12.0, which depends on
      async-http was resolved to 0.60.2, which depends on
        async-io was resolved to 1.35.0, which depends on
          async was resolved to 2.6.2, which depends on
            io-event
```

##### Resolution

To resolve this issue you can either:

* Remove github_changelog_generator from your `.sync.yml` and use another solution for changelog generation.

* Set the version requirement to 1.15.2 in your `sync.yml`.

After completing the step of your choice, you will need to run `pdk update` to ensure that your
Gemfile is updated accordingly.
