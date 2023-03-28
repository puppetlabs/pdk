# PDK known issues

## PDK 2.7.0

### `uninitialized constant` error

When selecting Puppet versions PDK, you may encounter an `uninitialized constant` error if the target version is below 6.29 for Puppet 6 or 7.22 for Puppet 7.

This is caused by an incompatible version of concurrent-ruby that is downloaded when PDK processes the selected Puppet version.

To mitigate this issue, we recommend selecting only the latest puppet versions when using `--puppet-version`.

For example:

#### Puppet 6

```
pdk validate --puppet-version 6.29
```

#### Puppet 7

```
pdk validate --puppet-version 7.22
```
The above issue should no longer be present when using `--pe-version`

### Install of pdk-2.7.0.0-1.el9.x86_64 conflicts with file from package

When installing an el9 based package the user may see the following errors:

```
file /usr/lib/.build-id/95/26c65fed0e95fbb6b988476cc811ca19d5c9c9 from install of pdk-2.7.0.0-1.el9.x86_64 conflicts with file from package libgcc-11.3.1-2.1.el9.x86_64
file /usr/lib/.build-id/ab/d5d7149726b0410af7af2e9a59491942605ddd from install of pdk-2.7.0.0-1.el9.x86_64 conflicts with file from package libstdc++-11.3.1-2.1.el9.x86_64
```

This is caused by conflicting build-ids in the package.

To avoid this issue, please target PDK 2.7.1.

## PDK 2.6.1

### Running autocorrect on puppet-lint top_scope_facts

Currently there is an issue with a third party plugin that the pdk currently pulls in called puppet-lint-top_scope_facts-check. When using the autocorrect functionality, it introduces issues in the codebase. 

In order to avoid running into this particular issue we recommend adding the following to your `.sync.yaml` file and then run a `pdk update`:

```
Rakefile:
  extra_disabled_lint_checks:
    - top_scope_facts
```

### `uninitialized constant` error

When selecting Puppet versions PDK, you may encounter an `uninitialized constant` error if the target version is below 6.29 for Puppet 6 or 7.22 for Puppet 7.

This is caused by an incompatible version of concurrent-ruby that is downloaded when PDK processes the selected Puppet version.

To mitigate this issue, we recommend selecting only the latest puppet versions when using `--puppet-version`.

For example:

#### Puppet 6

```
pdk validate --puppet-version 6.29
```

#### Puppet 7

```
pdk validate --puppet-version 7.22
```
In scenarios where `--pe-version` is used, it is recommended that `--puppet-version` is used instead, with the correct target as described above.

## PDK 1.15.0 is incompatible with Bundler 2.1.0 and later

PDK 1.15.0 is incompatible with Bundler 2.1.0 and later. Use Bundler 2.0.2
instead.

## PDK analytics opt-out dialog causing issues with CI systems

In PDK 1.11.0, when running in a Continuous Integration (CI) environment (such
as Travis CI), PDK may get stuck waiting for a response as to whether or not you
want to opt-out of anonymous analytics data collection.

PDK is intended to bypass this prompt in "non-interactive" environments such as
a CI environment. However, certain common CI environments are not being
correctly detected as "non-interactive". As an immediate workaround, avoid the
issue by configuring your CI jobs to run PDK with the `PDK_FRONTEND` environment
variable set to the value "noninteractive". For example, if running a
validation:

```
$ PDK_FRONTEND=noninteractive pdk validate
```

You might also be able to configure the environment variable for the entire job.
See
[https://docs.travis-ci.com/user/environment-variables/](https://docs.travis-ci.com/user/environment-variables/)
for information about configuring this in Travis CI, or check your CI system's
documentation for similar options.
[PDK-1414](https://tickets.puppetlabs.com/browse/PDK-1414),
[PDK-1415](https://tickets.puppetlabs.com/browse/PDK-1415)

## Using PDK with PowerShell ISE locks the console

If you run the `pdk new module` command inside a PowerShell ISE window, it
returns an error and locks the console. Do not use PDK with PowerShell ISE.
PDK-1168

## PDK not in ZShell PATH on Mac OS X

With ZShell on Mac OS X, PDK is not automatically added to the PATH. To fix
this, add the PATH by adding the line `eval $(/usr/libexec/path_helper -s)` to
the ZShell resource file (`~/.zshrc`).

## Output of `pdk test unit --list` lacks information

Output from `pdk test unit --list` lacks detailed information and tests appear
duplicated. To get the full text descriptions, execute the tests in JUnit format
by running `pdk test unit --format=junit`
[PDK-374](https://tickets.puppetlabs.com/browse/PDK-374)

## Module validation and testing might fail if dependencies include gems with native extensions

You might not be able to use PDK with a module if that module's Gemfile requires
Ruby gems with native extensions, particularly when running on Windows.

When you run `pdk validate` or `pdk test unit` on a module, PDK tries to install
any missing module dependencies before it runs validations or tests. On some
platforms, PDK can install gems with native extensions, if you already have the
required compilation tools and libraries installed. On Windows, however, the
Ruby installations managed by PDK are not configured to support native extension
compilation, even if the necessary tools are present.

If you encounter this issue on a platform other than Windows, you might be able
to resolve it by researching and installing the required dependencies for the
gem that is failing to install.

If you encounter this issue on a Windows platform, you must remove or comment
out the Gemfile dependencies that include native extensions or that have
dependencies that include native extensions.

