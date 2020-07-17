# PDK release notes

New features, enhancements, and resolved issues for the PDK 1.x release series.

## PDK 1.18.1

### Resolved issues

#### Ensure templates have access to metadata during an `update` or `convert`
Because templates didn't have access to metadata, it was possible for the module metadata config
to be empty during an `update` or `convert`. [PDK-1653](https://tickets.puppetlabs.com/browse/PDK-1653)

#### Don't attempt to modify a frozen string when parsing `--tests` paths
Fixes an issue that caused an error to be thrown when running `pdk test unit` and
specifying a path to a test using `--tests`. [#891](https://github.com/puppetlabs/pdk/pull/891)

## PDK 1.18

### New features and enhancements

#### PDK can determine applicable validators

PDK can now determine what validators are applicable based on the context from
which you are running
it.[PDK-1632](https://tickets.puppetlabs.com/browse/PDK-1632)

#### `environment.conf` file validation added

This release adds support for validating `environment.conf` files, which specify
per-environment settings. See the
[`environment.conf`](https://puppet.com/docs/puppet/latest/config_file_environment.html)
page for more information.
[PDK-1615](https://tickets.puppetlabs.com/browse/PDK-1615)

#### PDK now can warn for legacy Facter facts

You can now set PDK to warn, and optionally autocorrect, the use of legacy
Facter facts in your manifests. To enable this, set `disable_legacy_facts` to
`true` in the common section of their `.sync.yml` file. See the pdk-templates
[README](https://github.com/puppetlabs/pdk-templates/blob/master/README.md) for
detailed information. [PDK-1591](https://tickets.puppetlabs.com/browse/PDK-1591)

#### Set, update, delete configuration keys from command line

You can now set, update, add, or delete values in PDK configuration keys.

-   `pdk config del[ete] <key>`: Unsets values in the given configuration key.
-   `pdk config set [--add] <key> <value>`: Sets, updates, or adds to the values
    in the given configuration key.

[PDK-1108](https://tickets.puppetlabs.com/browse/PDK-1108),
[PDK-1109](https://tickets.puppetlabs.com/browse/PDK-1109)

### Resolved issues

#### Module creation could cause Puppet Server warnings

This release fixes an issue where an invalid `common.yaml` file was created
during the `pdk new module` or `pdk convert` processes, causing warnings in the
Puppet Server logs. [PDK-1633](https://tickets.puppetlabs.com/browse/PDK-1633)

#### Security fix for Nokogiri

This release resolves a security issue with Nokogiri. (CVE-2020-7595).
[PDK-1640](https://tickets.puppetlabs.com/browse/PDK-1640)

#### Fixes duplicated code created when converting, updating modules

When running `pdk convert` or `pdk update` in a subdirectory, boilerplate code
was recreated in the root directory. This is now fixed.
[PDK-1640](https://tickets.puppetlabs.com/browse/PDK-1640)

#### `pdk test unit --path` option no longer requires escaping Windows paths

Previously, you had to escape Windows paths to run `pdk test unit --path`. This
release fixes this issue so that RSpec accepts the paths without escaping.
[PDK-1640](https://tickets.puppetlabs.com/browse/PDK-1640)

#### Unbalanced JSON fragments now permitted in RSpec output

PDK now permits unbalanced JSON fragments in RSpec output.
[PDK-1640](https://tickets.puppetlabs.com/browse/PDK-1640)

## PDK 1.17

### New features and enhancements

#### Feature flags added to PDK

PDK now has [feature flags](https://en.wikipedia.org/wiki/Feature_toggle).
Activate feature flags by setting the environment variable PDK_FEATURE_FLAGS
with a comma separated list of flag names. For example:

Windows: `$ENV:PDK_FEATURE_FLAGS = 'feature1, feature2'`

*Nix and macOS: `export PDK_FEATURE_FLAGS=feature1,feature2`

See what flags are available using the `pdk get config` command.
[PDK-1618](https://tickets.puppetlabs.com/browse/PDK-1618)

#### Validator added for control repo context

PDK now optionally validates control repositories. This is a new feature and
requires the `controlrepo` feature flag to be set. Note that validation
generally requires a Gemfile, much like aPuppet module.
[PDK-1616](https://tickets.puppetlabs.com/browse/PDK-1616)

#### Added PDK configuration reader for INI files

PDK configuration now reads `environment.conf` files in directory-based Puppet
control repositories. Settings appear under the `pdk get config` command and
requires that the `controlrepo` feature flag be set.
[PDK-1614](https://tickets.puppetlabs.com/browse/PDK-1614)

#### `pdk config get` updated to `pdk get config`

In order to conform to standard syntax, PDK now uses `pdk get config` instead of
`pdk config get`. Note that `pdk config get` is deprecated and will be removed
in the future. [PDK-1607](https://tickets.puppetlabs.com/browse/PDK-1607)

#### Packaging configuration added for macOS 10.15 (Catalina)

PDK packages are now available for macOS 10.15 (Catalina).
[PDK-1522](https://tickets.puppetlabs.com/browse/PDK-152)

#### Deprecation: macOS 10.11, 10.12 removed

PDK packages are no longer available for macOS 10.11 or 10.12.
[PDK-1617](https://tickets.puppetlabs.com/browse/PDK-1617)

#### Template improvements

-   Travis CI template updated to allow Litmus tests to run for up to 45 minutes
    before timing out.
    [PDK-1620](https://tickets.puppetlabs.com/browse/PDK-1620)
-   If enabled, Travis CI template updated to run Litmus tests from an Ubuntu
    16.04 environment instead of 14.04.
    [PDK-1620](https://tickets.puppetlabs.com/browse/PDK-1620)
-   Travis CI and GitLab CI template configurations updated to use Ruby2.5.7
    instead of Ruby 2.5.3 when running tests.
    [PDK-1620](https://tickets.puppetlabs.com/browse/PDK-1620)
-   GitLab CI template updated to add support for advanced `only` and `except`
    conditions. [PDK-1620](https://tickets.puppetlabs.com/browse/PDK-1620)
-   Fixed the unhandled error when checking if the github_changelog_generator
    gem is installed when running `pdk release`.
    [PDK-1620](https://tickets.puppetlabs.com/browse/PDK-1620)

### Resolved issues

#### **ANSICON triggered when running PDK over WinRM**

Previously, PDK triggered ANSICON when running over WinRM. Now, PDK does not
call the ANSICON wrapper script when applied over a WinRM connection.
[PDK-1589](https://tickets.puppetlabs.com/browse/PDK-1589)

#### **Updated default order in hiera.yaml**

The hiera.yml template has been updated for new modules. Now, data from files
named after the operating system appear higher in the hierarchy than files named
after the operating system family.
[PDK-1690](https://tickets.puppetlabs.com/browse/PDK-1609)

## PDK 1.16

### New features and enhancements

#### Expanded analytics for `pdk bundle`

Analytics for the `pdk bundle` executions have been updated to include detailed,
but not identifying, usage information.
[PDK-1588](https://tickets.puppetlabs.com/browse/PDK-1588)

#### `pdk module build` now rejects unprintable characters in file names

To ensure that the module is compatible with all Puppet masters regardless of
their locale, `pdk module build` now rejects files that contain non-ASCII
characters in their name. Issue reported by [Laura
Macchi](https://tickets.puppetlabs.com/secure/ViewProfile.jspa?name=lmacchi).
[PDK-1587](https://tickets.puppetlabs.com/browse/PDK-1587)

#### cURL version upgraded to 7.68.0

cURL has been updated to version 7.68.0 in order to address CVEs.
[PDK-1586](https://tickets.puppetlabs.com/browse/PDK-1586)

#### Template reference added to `pdk new module` output

The `pdk new module` output has been modified to show the template reference
used to generate the module when it is not the default value.
[PDK-1545](https://tickets.puppetlabs.com/browse/PDK-1545)

#### Template improvements

-   `pdk-template` docs updated to clarify the required parameter in the
    `.gitignore` and `.pdkignore` templates.
    [PDK-1596](https://tickets.puppetlabs.com/browse/PDK-1596)
-   `frozen_string_literal` magic comment added to templated Ruby files.
    [PDK-1596](https://tickets.puppetlabs.com/browse/PDK-1596)
-   `transport_device` object template fixed so that `PDK::Util::NetworkDevice`
    is now properly defined as a class instead of a
    module.[PDK-1596](https://tickets.puppetlabs.com/browse/PDK-1596)
-   `use_litmus` parameter added to the `.travis.yml` to allow Travis CI to be
    easily configured to use Litmus for module acceptance
    tests.[PDK-1596](https://tickets.puppetlabs.com/browse/PDK-1596)

### Resolved issues

#### PDK correctly places files based on module root

When running a PDK command, such as `pdk new class`, from within a module
subdirectory, PDK now generates files in a location based on the module root
rather than relative to where the command was executed.
[PDK-1556](https://tickets.puppetlabs.com/browse/PDK-1556)

## PDK 1.15

### New features and enhancements

#### Convert module to default template

You can now run `pdk convert --default-template` to convert a module to the
default PDK template. [PDK-1487](https://tickets.puppetlabs.com/browse/PDK-1487)

#### `pdk_update` warns if pinned to old version of template

`pdk update` checks if a module is pinned to a template version. If it is, `pdk
update` notifies and instructs you on how to unpin the template version.
[PDK-1488](https://tickets.puppetlabs.com/browse/PDK-1488)

#### Git version updated to 2.24.0

The current version of Git included in PDK and been updated to 2.24.0.
[PDK-1529](https://tickets.puppetlabs.com/browse/PDK-1529)

#### Platform configuration updated to Fedora 31

PDK packages are no longer being built for Fedora 28 and Fedora 29, which are
both now at end of life. PDK packages are now being built for Fedora 31.
[PDK-1546](https://tickets.puppetlabs.com/browse/PDK-1546)

#### Template improvements

-   Automatic deployment of modules to the Forge via Travis CI is now opt-out
    optional. [PR 289](https://github.com/puppetlabs/pdk-templates/pull/289)
-   The default `before_script` commands in the GitLab CI configuration can now
    be disabled. [PR 299](https://github.com/puppetlabs/pdk-templates/pull/299)
-   Deeply nested data structures in the GitLab CI configuration custom
    overrides are now rendered correctly. [PR
    298](https://github.com/puppetlabs/pdk-templates/pull/298)

### Resolved issues

#### `pdk convert --template-url /tmp/pdk-template` fails if not a Git repository

Updating and converting modules can now use a plain template directory on disk.
The template directory longer has to be a Git-based repository.
[PDK-1364](https://tickets.puppetlabs.com/browse/PDK-1364)

#### PDK breaks when run from Vagrant's shared directory

A Ruby issue prevented PDK file rename operations from operating inside
directories shared with VMWare Workstation. This release resolves this issue.
[PDK-1169](https://tickets.puppetlabs.com/browse/PDK-1169)

#### PDK PowerShell module set environment variables once during loading

The PDK PowerShell module set environment variables only once during the module
loading process and then failed with a Ruby error. The necessary environment
variables are now set on every invocation.
[PDK-1547](https://tickets.puppetlabs.com/browse/PDK-1547)

## PDK 1.14

### New features and enhancements

#### `pdk new test --unit` command finalized

The unit test creation command, experimentally named `pdk new unit_test`, has
been changed to `pdk new test --unit`. This command creates basic unit test
templates for classes and defined types. See the [PDK command
reference](pdk_reference.md) for usage details.
[PDK-1495](https://tickets.puppetlabs.com/browse/PDK-1495)

#### Default `ipaddress6` fact value added

This release adds a default `ipaddress6` fact value to the `default_facts.yml`
template. [PR-278](https://github.com/puppetlabs/pdk-templates/pull/278)

#### Puppet 4 compatibility deprecated

A deprecation warning is displayed if you select a Puppet version less than
5.0.0 for use with PDK. Puppet 4 reached end of life in October 2018.
[PDK-1367](https://tickets.puppetlabs.com/browse/PDK-1367)

#### Add unit test templates to converted modules

The `pdk convert` command has a new `--add-tests` option that generates unit
test templates for any classes or defined types that don't have tests.
[PDK-1047](https://tickets.puppetlabs.com/browse/PDK-1047)

#### Compatible with interactive debugging tools

Unit testing now supports interactive Ruby debugging tools, such as `pry`. These
tools work with PDK for default output only, not with custom outputs specified
with the `--format` option.
[PDK-680](https://tickets.puppetlabs.com/browse/PDK-680)

#### Experimental debugging command added

This release adds an experimental `pdk console` subcommand, which provides a
Puppet code "read–evaluate–print loop" (REPL), powered by the `puppet-debugger`
tool. To test this functionality, see the PDK GitHub project
[README](https://github.com/puppetlabs/pdk/blob/2be8a94c91e4947255ea18f55ac161fae9a54753/README.md#pdk-console-command).
[PDK-1505](https://tickets.puppetlabs.com/browse/PDK-1505)

### Resolved issues

#### `pdk validate` no longer warns about quoted Booleans

Module validation no longer warns about quoted Boolean values in Puppet code,
because this is no longer prohibited by the Puppet language style guide.
[PDK-1176](https://tickets.puppetlabs.com/browse/PDK-1176)

#### Rubocop profile setting is now respected

Prior to this release, `pdk validate` ran `rubocop-i18n` checks even if the
Rubocop profile was set to off. This has been fixed.
[PDK-1439](https://tickets.puppetlabs.com/browse/PDK-1439)

#### Empty array and hash values are correctly rendered for GitLab CI

Empty array and empty hash values are now correctly rendered in the
`.gitlab-ci.yml` template. Contributed by [seanmil](https://github.com/seanmil)
in[PR-276](https://github.com/puppetlabs/pdk-templates/pull/276)

### PDK 1.14.1

#### Puppet Litmus supported on more platforms

PDK is now compatible with a broader range of versions of the Minitar gem, which
allows PDK to be used in conjunction with Litmus on more platforms, including
Windows. [PDK-1525](https://tickets.puppetlabs.com/browse/PDK-1525)

#### Improved error handling for module creation

Module creation with the `skip-interview` flag failed with an unhelpful error
message if the module name was omitted.
[PDK-1527](https://tickets.puppetlabs.com/browse/PDK-1527)

#### Ruby older than 2.4 deprecated

If you try to run PDK commands with a Ruby version older than 2.4, a deprecation
warning is returned. Support for deprecated Ruby versions will be removed in a
future release. [PDK-1519](https://tickets.puppetlabs.com/browse/PDK-1519)

#### Improved tempfile and environment variable handling for Windows

PDK now reads command output in binary mode, preserving the line endings used on
Windows. Environment variables on Windows are accessed with the internal Windows
kernel32 methods, preserving non-ASCII values in the environment variables.
[PDK-1443](https://tickets.puppetlabs.com/browse/PDK-1443)

#### Unit tests failed if operating system metadata contained special characters

Previously, unit tests failed if the "operatingsystemrelease" values in the
`metadata.json` file contained special regular expression characters such as
parentheses. This no longer causes tests to fail.
[PDK-1207](https://tickets.puppetlabs.com/browse/PDK-1207)

#### Improved handling of sensitive values in templates

The transport object template now properly unwraps sensitive values before
comparing them. [PR-286](https://github.com/puppetlabs/pdk-templates/pull/286/)

#### Improved error handling for templates

PDK now more reliably raises a useful error when there is an issue reading or
rendering a template. Originally contributed by
[logicminds](https://github.com/logicminds) in
[PR-794](https://github.com/puppetlabs/pdk/pull/794).

#### `pdk console` now updates local clone of Puppet with the `puppet-dev` flag

The `pdk console` command did not update the local clone of Puppet even if you
ran it with the `--puppet-dev` flag. This issue is fixed, so now the flag
correctly incorporates the latest Puppet changes.
[PR-792](https://github.com/puppetlabs/pdk/pull/792)

#### `pdk test unit --verbose` did not change RSpec's output format

Prior to this release, if you used the `--verbose` flag with the `pdk test unit`
command, the RSpec output format did not change. Now the output format correctly
changes from `progress` to `documentation`.
[PR-791](https://github.com/puppetlabs/pdk/pull/791)

#### Fixed broken URL in provider error message

This release fixes a provider error message that displayed an incorrect URL to
the resource API documentation. Contributed by
[michaeltlombardi](https://github.com/michaeltlombardi) in
[PR-780](https://github.com/puppetlabs/pdk/pull/780).

#### Added `~` suffix to default `.gitignore` template

This release adds the tilde (`~`) suffix, commonly used for temporary and backup
text files, to the default `.gitignore` template. Contributed by
[freiheit](https://github.com/freiheit) in
[PR-285](https://github.com/puppetlabs/pdk-templates/pull/285).

## PDK 1.13

### New features and enhancements

#### `pdk convert` creates missing init-only files

Converting a module to PDK now creates any missing init-only templated files,
such as README.md. Previously, there was no mechanism in PDK for adding these
templates to existing modules.
[PDK-1363](https://tickets.puppetlabs.com/browse/PDK-1363)

#### Generate unit or class spec test skeletons

This release adds a new experimental command, `pdk new unit_test`. This command
generates missing unit or class spec test skeletons. The interface for this
command is still being finalized and will likely change before the command is
fully enabled in a future release. For usage information, run `pdk new unit_test
--help` .[PDK-1175](https://tickets.puppetlabs.com/browse/PDK-1175)

#### `pdk config get` command retrieves PDK configuration

The new `pdk config get` command retrieves the complete resolved configuration
for PDK, including all available layers of configuration. If run from within a
module, the command returns both user-level and module-level configuration
settings. If run outside of a module, the command returns only user-level
configuration and a message that the command was not invoked from within a
module. See the [PDK command reference](pdk_reference.md) for usage examples
and options. [PDK-1107](https://tickets.puppetlabs.com/browse/PDK-1107)

#### Improvements to default hierarchy in new modules

The default `hiera.yaml` hierarchy configuration for new modules now includes
`osfamily/major release` and `osfamily` layers ahead of the "common" layer.
Contributed by [ghoneycutt](https://github.com/ghoneycutt),
[PR206](https://github.com/puppetlabs/pdk-templates/pull/206).

### Resolved issues

#### PDK Windows package could not be installed on some systems

Resolved an issue that prevented the PDK MSI (Windows) package from being
installed on systems where legacy "8dot3" style file name creation is disabled.
[PDK-1468](https://tickets.puppetlabs.com/browse/PDK-1468)

#### Security update to `nokogiri` gem

The bundled version of the `nokogiri` gem has been updated to 1.10.4 in PDK's
Ruby 2.4 and Ruby 2.5 environments to address a security issue.

#### Changelog generator Rake tasks used incorrect defaults

Prior to this fix, the default value for `changelog_project` was not correctly
derived from a module's metadata. Contributed by
[genebean](https://github.com/genebean),
[PR272](https://github.com/puppetlabs/pdk-templates/pull/272).

#### `pdk validate` returned errors for bare directory names

Previously, `pdk validate` returned an error if you passed a bare directory name
as an argument. [PR724](https://github.com/puppetlabs/pdk/pull/724)

#### New module generation failed if template files were deleted

Fixed an issue where `pdk new module` could fail if the template being used
contained one or more files configured with "delete: true" in the
`config_defaults.yml` file. Contributed by
[seanmil](https://github.com/seanmil),[PR725](https://github.com/puppetlabs/pdk/pull/725).

## PDK 1.12

### New features and enhancements

#### New platforms supported

Packages are now available for Debian 10, Fedora 30, Red Hat For installation
details, see [Installing PDK](pdk_install.md#install-on-rhel-sles-or-fedora).

#### Global setting for Facter version added to `rspec-puppet-facts`

This release adds a `default_facter_version` RSpec option to
`rspec-puppet-facts`, included in PDK. This option allows you to set the default
Facter version used when searching FacterDB with `os_supported_os` in RSpec
tests. For details, see the [`rspec-puppet-facts`
project](https://github.com/mcanevet/rspec-puppet-facts/pull/88).
[PDK-1394](https://tickets.puppetlabs.com/browse/PDK-1394)

#### Updated metadata default operating system release versions

The default `operatingsystem_support` metadata values used when creating new
modules has been updated to the current latest versions of each operating
system. [PDK-1366](https://tickets.puppetlabs.com/browse/PDK-1366)

#### Building a module package ensures that files and directories have correct permissions

The `pdk build` command now ensures that when it adds files and directories to
the module package, they have permissions that allow anyone to read them when
the package is extracted.
[PDK-1309](https://tickets.puppetlabs.com/browse/PDK-1309)

#### Windows installation improved

The PDK MSI package installs, upgrades, and uninstalls on Windows significantly
faster. [PDK-1274](https://tickets.puppetlabs.com/browse/PDK-1274)

#### `pdk bundle` commands can be interacted with

Commands invoked through the `pdk bundle` subcommand can now be interacted with.
Previously, the command's output streams were buffered, and there was no way to
supply any input. This should allow you to use experimental features such as
`pdk bundle console` or invoking `rake` tasks that require user interaction.
[PDK-641](https://tickets.puppetlabs.com/browse/PDK-641)

#### EPP file validation added

PDK can now validate the syntax of embedded Puppet (`.epp`) files inside a
module. [PDK-421](https://tickets.puppetlabs.com/browse/PDK-421)

#### New template settings for `puppet-lint` warnings, gem source

You can now configure `pdk-templates` to turn `puppet-lint` warnings into
errors. To configure this setting, in your `sync.yml` file, set the `Rakefile`
key to the value `linter_fail_on_warnings`.

You can also specify a per-gem `source` value in `pdk-templates`. This allows
gems to be installed from non-standard sources such as private `rubygems`
mirrors. To configure this, set the `Gemfile` key in your `sync.yml` file.

Changes contributed by Sean Millichamp. For details about PDK template settings,
see the [`pdk-templates` repo](https://github.com/puppetlabs/pdk-templates)
documentation. [PDK-1417](https://tickets.puppetlabs.com/browse/PDK-1417),
[PDK-1416](https://tickets.puppetlabs.com/browse/PDK-1416)

### Resolved issues

#### **PDK failed with a YAML error if Bolt config file was invalid**

This release fixes an issue where an incorrectlly formatted Bolt analytics
config file caused an unconfigured installation of PDK to exit with an error.
[PDK-1434](https://tickets.puppetlabs.com/browse/PDK-1434)

#### `pdk validate` command failed on some macOS versions

Resolved an issue where on some versions of macOS, the `pdk validate` command
returned errors because the PDK's bundled `rubocop-i18n` gem had incorrect
permissions. [PDK-1433](https://tickets.puppetlabs.com/browse/PDK-1433)

#### Default facts now override facts from `rspec-puppet-facts`

When running unit tests, specified default facts didn't correctly override
`rspec-puppet-facts`. Now when you run unit tests, default facts — as defined in
`spec/default_facts.yml` or `spec/default_module_facts.yml` — override any
conflicting facts that come from FacterDB. Contributed by Nick Walker in [PR
#257](https://github.com/puppetlabs/pdk-templates/pull/257).

## PDK 1.11

### New features and enhancements

#### PDK collects anonymous analytics data

PDK now gathers anonymous data about your PDK usage. This data helps us
understand how you use PDK and how we can improve it. You can opt out of data
collection at any time. For details about what data is collected, how your data
is anonymized, and how to opt out, see [PDK analytics](pdk_install.md#analytics).

#### New modules default to latest Puppet version

Prior to this release, new modules defaulted to Puppet 5 with Ruby 2.4. Now new
modules default to the latest Puppet version available to PDK. As of this
release, this is Puppet 6 with Ruby 2.5.
[PDK-1365](https://tickets.puppetlabs.com/browse/PDK-1365)

#### Git in PDK now reads standard `gitconfig` locations

PDK's included version of Git now reads the standard locations for `gitconfig`
files on non-Windows platforms, such as `/etc/gitconfig`and `$HOME/.gitconfig`.
[PDK-1378](https://tickets.puppetlabs.com/browse/PDK-1378)

#### Improved protection against updating modules to outdated PDK versions

This release improves protection against applying outdated changes to
PDK-compatible modules. You cannot update a PDK-compatible module to a PDK
version older than the version specified in the module's metadata. Prior to this
release, running `pdk update` with an older version of PDK returned only a
warning.

To override this check, run `pdk update --force`.
[PDK-1343](https://tickets.puppetlabs.com/browse/PDK-1343)

#### Template improvements

This release contains several updates to PDK templates, including improvements
generously contributed by community members. Updates include:

-   Updated the Travis CI configuration template to make the test environment
    image name configurable. Contributed by ghoneycutt in [PR
    #222](https://github.com/puppetlabs/pdk-templates/pull/222).
-   Updated Travis CI configuration template to allow the customiszation of the
    `BEAKER_PUPPET_COLLECTION` environment variable when running acceptance
    tests with Beaker. Contributed by treydock in [PR
    #249](https://github.com/puppetlabs/pdk-templates/pull/249).
-   Updated the Travis CI configuration to run tests on the Ubuntu 16.04 image
    by default instead of the Ubuntu 14.04 image.
-   Updated Travis CI configuration template to allow the customization of the
    `before_deploy` commands.
-   Updated GitLab CI configuration template to allow the customization of the
    `before_script` commands. Contributed by LHenke in [PR
    #238](https://github.com/puppetlabs/pdk-templates/pull/238).
-   Updated the Rubocop configuration to not enforce the externalization of
    strings in test files, which are located in the `spec` folder.
-   Updated Appveyor configuration template to optionally generate SimpleCov
    code coverage reports.
-   Added a VSCode recommended extensions file that suggests that VSCode users
    install the Puppet and Ruby extensions if they're not already present.
-   Automatically enable the Litmus rake tasks if Litmus is available.

### Resolved issues

#### Security updates to curl

This release includes an update to the packaged curl to address vulnerabilities.
See the curl issues
[CVE-2019-5435](https://curl.haxx.se/docs/CVE-2019-5435.html) and
[CVE-2019-5436](https://curl.haxx.se/docs/CVE-2019-5436.html) for details about
these issues. [PDK-1369](https://tickets.puppetlabs.com/browse/PDK-1369)

#### Default `template-ref` for custom templates is now "master"

With PDK installed from a package, if you've specified a custom template for
PDK, the default `template-ref` is now "master". Prior to this release, the
`template-ref` defaulted to the default version of the packaged template.
[PDK-1354](https://tickets.puppetlabs.com/browse/PDK-1354)

#### `rspec-puppet` incorrectly reported coverage failure

Prior to this release, `rspec-puppet` marked unit tests as successful despite
failure in coverage. This has now been fixed, and `rspec-puppet` correctly
reports insufficient resource coverage.
[PDK-1374](https://tickets.puppetlabs.com/browse/PDK-1347)

#### PDK returns a warning and unsets version environment variables

If you try to use the environment variables `PUPPET_GEM_VERSION`,
`FACTER_GEM_VERSION`, or `HIERA_GEM_VERSION`, PDK now returns a warning and
unsets the variables so they do not affect the `pdk` command. If you try to use
the `PUPPET_GEM_VERSION` environment variable, the warning suggests that you use
the `--puppet-version` option or the `PDK_PUPPET_VERSION` environment variable
instead. [PDK-1337](https://tickets.puppetlabs.com/browse/PDK-1337)

#### GitLab CI template updated to merge custom values correctly

The GitLab CI configuration template has been updated so that the custom values
are merged into the default values in the correct order.

#### Community contributed bug fixes

This release adds several community-contributed fixes to the PDK templates.
Issues resolved include:

-   Resource API providers generated with `pdk new provider` are now generated
    with Puppet Strings-compatible documentation. Contributed by ghoneycutt in
    [PR #199](https://github.com/puppetlabs/pdk-templates/pull/199).
-   Updated the TravisCI configuration template to include the `deploy`
    configuration only if it has been configured in `.sync.yml`. Contributed by
    ghoneycutt in [PR
    #223](https://github.com/puppetlabs/pdk-templates/pull/223).
-   The default GitHub changelog generator project name is now generated from
    the `source` metadata value instead of the `name` metadata value, because
    the module name often does not exactly match the repository name.
    Contributed by rnelson0 in [PR
    #231](https://github.com/puppetlabs/pdk-templates/pull/231).

### PDK 1.11.1

#### PDK analytics opt-out prompt was not bypassed by setting `PDK_DISABLE_ANALYTICS`

Setting the `PDK_DISABLE_ANALYTICS` environment variable now bypasses the
initial analytics opt-out prompt that PDK presents when no analytics
configuration file is found.
[PDK-1415](https://tickets.puppetlabs.com/browse/PDK-1415)

#### PDK did not recognize common CI environments as non-interactive

PDK now uses additional environment variables to detect common CI environments
and treats those environments as "noninteractive", disabling prompts and complex
user interface output.
[PDK-1414](https://tickets.puppetlabs.com/browse/PDK-1414)

## PDK 1.10

### New features and enhancements

#### Specify custom template references

You can now specify a branch name, tag name, or commit SHA for the template
repository that PDK uses for your modules. The `--template-ref` option is
available for the following commands:

-   `pdk new module`

-   `pdk convert`

-   `pdk update`


[PDK-718](https://tickets.puppetlabs.com/browse/PDK-718)

#### Improvements to PDK template

This release adds several community-contributed updates to the templates. See
PDK's GitHub [templates repository](https://github.com/puppetlabs/pdk-templates)
for pull request details.
[PDK-1332](https://tickets.puppetlabs.com/browse/PDK-1332)

Improvements include:

-   Added "build stages" to default Travis CI configuration. (PR #172 by rtib)

-   Added "changelog_version_tag_pattern" configuration option to improve
    compatibility between `github-changelog-generator` and `puppet-blacksmith`.
    (PR #185 by rtib)

-   Fixed style issues with template generated classes and defined types. (PRs
    #195 and #197 by ghoneycutt)

-   Added additional entries to default `.pdkignore` and `.gitignore`. (PRs
    #200, #201, #202, and #219 by ghoneycutt)

-   Updated Ruby versions in default Travis CI configuration to match recent
    Puppet releases. (PRs #204 and #216 by ghoneycutt)


#### Generated files end with trailing newline character

When PDK generates a file that is not based on a template, such as
`metadata.json`, it adds a trailing newline character to the end of the file.
[PDK-1308](https://tickets.puppetlabs.com/browse/PDK-1308)

#### Building a module package now warns of incomplete module metadata

The `pdk build --force` command now prints a warning if your module metadata is
incomplete, but continues to build the module package instead of failing.
PDK-1086

### Resolved issues

#### Security updates to Ruby

This release includes a patch to the packaged RubyGems to address security
issues. For more details, see the Ruby [security
advisories](http://blog.rubygems.org/2019/03/05/security-advisories-2019-03.html).
[PDK-1304](https://tickets.puppetlabs.com/browse/PDK-1304)

## PDK 1.9

### New features and enhancements

#### Validation for YAML file syntax

The `pdk validate` command now includes syntax validation of YAML files in the
module. [PDK-735](https://tickets.puppetlabs.com/browse/PDK-735)

#### Updated packages for Fedora

This release adds PDK packages for Fedora 28 and 29. Packages for Fedora 26 and
27, which have reached end of life, are no longer available.
[PDK-1050](https://tickets.puppetlabs.com/browse/PDK-1050)

#### Ignores development-related files when building module packages

The `.pdkignore` template has been updated so that development related files are
not included when building module packages for publishing to the Forge.
Development-related files that are now ignored during building include Rakefile,
Gemfile, tests under the `/spec/` directory, and CI configuration.
[PDK-957](https://tickets.puppetlabs.com/browse/PDK-957)

#### New package for Mac OS X Mojave

This release adds a PDK package for Mac OS X 10.14 (Mojave).
[PDK-1250](https://tickets.puppetlabs.com/browse/PDK-1250)

### Resolved issues

#### Validation no longer fails when run from a subdirectory

This release fixes a bug where PDK was not evaluating file targets based on the
current working directory. This caused `pdk validate <TARGET>` to fail when run
from a module's subdirectory.
[PDK-1204](https://tickets.puppetlabs.com/browse/PDK-1204)

#### Recognizes valid local template directory in answer file

This release fixes an issue where if the local template directory was not a Git
repository, PDK falsely reported that a valid local template directory set in
the answer file was invalid.
[PDK-914](https://tickets.puppetlabs.com/browse/PDK-914)

#### Rake task conflict fixed in `puppetlabs_spec_helper`

The `puppetlabs_spec_helper` Rake task `check:test_files` no longer interferes
with any tasks that might run after it in the same Rake command, such as `rake
test:test_files rubocop`.
[PDK-997](https://tickets.puppetlabs.com/browse/PDK-997?)

#### Internal software update for PDK for Windows

The ANSICON software in PDK for Windows has been updated to the latest available
version. This fixes some PDK execution errors encountered on Windows 10.
[PDK-1139](https://tickets.puppetlabs.com/browse/PDK-1139)

#### Improved support for older Git versions

This release changes the way PDK executes Git to support older versions of
Git.PDK now changes directory into the Git repository before running `git`
commands, rather than using `git -C`.
[PDK-1001](https://tickets.puppetlabs.com/browse/PDK-1001)

#### Validation no longer fails if modules include gems with symlinks.

Fixes a bug where modules with bundled gems that include symlinks failed
validation. [PDK-1199](https://tickets.puppetlabs.com/browse/PDK-1199)

#### PDK honors puppet-lint configurations in the template

Because PDK executes `puppet-lint` directly instead of calling the Rake command,
PDK did not honor the `puppet-lint` configurations specified in the Rakefile. In
this release, PDK now honors the Rakefile configuration options for puppet-lint
set up in the default template config and `.sync.yml`.
[PDK-1202](https://tickets.puppetlabs.com/browse/PDK-1202)

### PDK 1.9.1

#### Improvements to PDK module template

The release includes several improvements to the PDK template, contributed by
Puppet community members. See the merged pull requests for details about each
change.

-   Increased control of `puppet-lint` configuration, such as disabling certain
    checks. [PR 181](https://github.com/puppetlabs/pdk-templates/pull/181/files)

-   Improved description of `moduleroot_init` in the `pdk-template` README. [PR
    188](https://github.com/puppetlabs/pdk-templates/pull/188)

-   Added the ability to permit aliases in default fact files. [PR
    189](https://github.com/puppetlabs/pdk-templates/pull/190)


#### GitLab CI configuration updated

This release updates the GitLab CI configuration to test and validate against
Puppet 5 and 6, which are the current versions of Puppet.
[PDK-1277](https://tickets.puppetlabs.com/browse/PDK-1277)

#### PDK no longer attempts to validate targets that are not files

When validating YAML, PDK now filters out any targets that are not files. This
prevents PDK from trying to validate targets that it should not be validating,
such as a testing folder called `default.yml`.
[PDK-1276](https://tickets.puppetlabs.com/browse/PDK-1276)

#### PDK returned an error if some Ruby symbols were in YAML files

PDK validation now supports the use of Ruby symbols, such as a colon preceding a
value (`:ssh`), in YAML files.
[PDK-1273](https://tickets.puppetlabs.com/browse/PDK-1273)

#### Slashes in module names are automatically corrected

When converting modules to PDK, if the module's name in the `metadata.json` file
is formatted with a slash instead of a hyphen, PDK corrects the name
automatically. For example, if the module name is `puppetlabs/apache` in the
metadata, PDK changes it to `puppetlabs-apache`.
[PDK-1272](https://tickets.puppetlabs.com/browse/PDK-1272)

#### False syntax validation errors fixed

This release fixes an issue where PDK produced false syntax errors when
validating modules that contain example manifests in the `examples` directory.
This issue occurred only if the module was located in Puppet's configured
`modulepath`. [PDK-1266](https://tickets.puppetlabs.com/browse/PDK-1266)

## PDK 1.8

### New features and enhancements

#### Newly created modules require Puppet 4.10.0 or greater by default

With recently added support for data-in-modules, the PDK module template has
been updated with a Puppet requirement lower bound of ">= 4.10.0". This affects
newly generated modules.
[[PDK-1208](https://tickets.puppetlabs.com/browse/PDK-1208)]

#### New module template adds support for data in modules

When you generate a new module, PDK renders a default `hiera.yaml` file. This
supports the addition of Hiera data in modules. This is true only for newly
created modules; converting or updating existing modules does not add this file.
[[PDK-1237](https://tickets.puppetlabs.com/browse/PDK-1237)]

#### Support for testing against Ruby 2.5.1

Appveyor and Travis are updated to test against Ruby 2.5.1.
[[PDK-1237](https://tickets.puppetlabs.com/browse/PDK-1237)]

### Resolved issues

#### Reported time of `pdk test unit` execution is consistent

Previously, running the `pdk test unit` command returned an execution time
calculated as only the time running tests, while running the command with the
`--parallel` option returned the total time of loading files and running tests.
This command now consistently reports a total time of execution.
[[PDK-400](https://tickets.puppetlabs.com/browse/PDK-400)]

#### Updated curl with security fixes

This release updates the packaged curl to 7.62.0 to include security fixes.
[[PDK-1212](https://tickets.puppetlabs.com/browse/PDK-1212)]

#### Files have LF line endings

When PDK generates files, they now always have LF line endings instead of CRLF
line endings. [[PDK-547](https://tickets.puppetlabs.com/browse/PDK-547)]

#### `pdk validate` command honors Rubocop excludes

Prior to this fix, running `pdk validate` without any targets caused the
subsequent Rubocop call to ignore the `rubycop.yml` excludes. This has been
fixed and the Ruby validator will now honor the excludes in the `rubocop.yml`.
[[PDK-654](https://tickets.puppetlabs.com/browse/PDK-654)]

#### `pdk build` no longer adds Puppet 6.0 gem dependency

Previously, the `pdk build` command incorrectly modified the module's
`Gemfile.lock` file, adding a Puppet 6.0 gem dependency. The build command no
longer modifies the `Gemfile.lock` file.
[[PDK-1190](https://tickets.puppetlabs.com/browse/PDK-1190)]

#### Validation no longer checks the module package

By default, the `pdk validate` command now excludes the `<modulename>/pkg`
directory, which contains the module package.
[[PDK-1183](https://tickets.puppetlabs.com/browse/PDK-1183)]

#### Testing skips empty `default_facts.yml` file

Previously, if a module's `spec/default_facts.yml` file was empty, `pdk test
unit` failed all tests. PDK now silently skips empty `spec/default_facts.yml`
and `spec/default_facts_module.yml` files. If the file is not empty, but does
not contain valid YAML data, a warning is shown in the `pdk test unit` output.
[[PDK-1191](https://tickets.puppetlabs.com/browse/PDK-1191)]

#### `pdk update` no longer generates false file removal warnings

If your `.sync.yml` file specified a given file to be deleted, the `pdk update`
command generated a file removal warning even in cases where the file was not
present. This has been fixed.
[[PDK-972](https://tickets.puppetlabs.com/browse/PDK-972)]

#### `pdk convert` updates null values and empty arrays in metadata

Prior to this release, modules converted to PDK compatibility failed validation
if their original metadata contained requirements or dependencies keys with null
values or empty arrays, because PDK did not replace those values with valid
ones. Now when a module is converted, PDK replaces null values with the default
metadata value. Additionally, if the requirements array is present but empty,
PDK updates it with the default metadata value.
[[PDK-1093](https://tickets.puppetlabs.com/browse/PDK-1093)]

#### Testing against the Puppet code source works correctly 

Previously, the `--puppet-dev` option for the `pdk test unit` and `pdk validate`
commands didn't correctly use the Puppet source.
[[PDK-1200](https://tickets.puppetlabs.com/browse/PDK-1200)]

#### Testing and validation ignores files in vendor directories

Prior to this fix, PDK scanned vendor directories and failed validation on any
`.pp` files these directories contained. The `pdk validate` and `pdk unit test`
commands now ignore files in the vendor directory.
[[PDK-1192](https://tickets.puppetlabs.com/browse/PDK-1192)]

#### Validation returned an error if a module contained Puppet task plans

If modules contained plans, `pdk validate` returned an error. PDK now excludes
the `plans` directory during validation.
[[PDK-1194](https://tickets.puppetlabs.com/browse/PDK-1194)]

#### Bundler environment is created on module creation 

When you create a new module, PDK now sets up a Ruby Bundler environment and
creates a `Gemfile.lock` file. Previously, this environment was not created
until the first time you ran a PDK command in the module.
[[PDK-1172](https://tickets.puppetlabs.com/browse/PDK-1172)]

#### Resource creation uses the configured module template

When generating resources, such as classes or defined type, PDK was not using
the configured template URL from the `metadata.json` file. Now, PDK uses the
same template for resources that was used in the module's
creation. [[PDK-1104](https://tickets.puppetlabs.com/browse/PDK-1104)]

#### PDK now works correctly in Bundler setups

When running PDK from a gem install, PDK no longer overrides any existing user
specified Bundler gem install path. This allows PDK in Bundler setups to work
correctly. [[PDK-1187](https://tickets.puppetlabs.com/browse/PDK-1187)]

#### PDK manages the `.gitattributes` file

Previously, PDK managed the `.gitattributes` file only at initialization. This
file has been moved to the module root and is actively managed by PDK.
[[PDK-1211](https://tickets.puppetlabs.com/browse/PDK-1211)]

#### Error handling improved for PDK version metadata with null values

If the module's metadata contained a null value for the `pdk-version` key, PDK
quit unexpectedly with a Ruby exception. This release fixes this issue so that
PDK instead exits with an error if it encounters this issue.
[[PDK-1180](https://tickets.puppetlabs.com/browse/PDK-1180)]

## PDK 1.7

### New features and enhancements

#### Validate and unit test against latest Puppet development code

This release adds the `--puppet-dev` flag to the `pdk validate` and `pdk test
unit` commands. This flag allows users to validate and test against the latest
Puppet source code from GitHub. You must have internet access to
[https://github.com](https://github.com,) to use this option. You cannot specify
`--puppet-dev` together with the `--puppet-version=` or `--pe-version=` options.
[[PDK-1096](https://tickets.puppetlabs.com/browse/PDK-1096)]

#### Module creation default options are consistently generated

Running `pdk new module <module> --skip-interview` now generates the same
metadata as if you ran `pdk new module <module>` and accepted all the default
answers to the interview questions.
[[PDK-583](https://tickets.puppetlabs.com/browse/PDK-585)]

#### Support for testing against Puppet 6

This release adds support for validating and running unit tests against Puppet 6
with Ruby 2.5. [[PDK-1056](https://tickets.puppetlabs.com/browse/PDK-1056),
[PDK-1141](https://tickets.puppetlabs.com/browse/PDK-1141)]

### PDK 1.7.1

#### Improved reference documentation and help output for validating modules in PowerShell

Reference documentation and command line help output now states that when you
run multiple specific validations in PowerShell, you must enclose the list of
validators in single quotes. Without the quotes, PowerShell cannot interpret the
command correctly and returns an error. For example: `pdk validate
'puppet,metadata'`. See for details.
[[PDK-1173](https://tickets.puppetlabs.com/browse/PDK-1173)]

#### Updated curl with security fixes

This release updates the packaged curl to 7.61.1 to include security fixes.
[[PDK-1182](https://tickets.puppetlabs.com/browse/PDK-1182)]

## PDK 1.6

### New features and enhancements

#### GitLab CI default configuration improved

The release improves testing and validation parity between GitLab CI and Travis
CI. The default GitLab CI configuration now runs spec tests against Puppet 4
with Ruby 2.1.9 and Puppet 5 with Ruby 2.4.4. It also supports lint, syntax, and
Rubocop checks for Ruby version 2.4.4. You can add to or override these versions
by editing your module's `.gitlab-ci.yml`.

#### PDK no longer deletes test fixtures by default 

You can now specify whether PDK should clean up test fixtures, such as symlinks
and external module dependencies, after running `pdk test unit`. Prior to this
release, PDK cleaned up test fixtures after every run of `pdk test unit`. This
often caused longer test runs, because fixtures weren't stored, but had to be
downloaded every time you invoked the `pdk test unit` command.

PDK no longer deletes test fixtures after running unit tests. To have PDK remove
the text fixtures, run the `pdk test unit` command with the clean fixtures flag:
`pdk test unit --clean-fixtures` or `pdk test unit -c`.
[[PDK-636](https://tickets.puppetlabs.com/browse/PDK-636)]

#### Remove values from the default module template configuration

This release allows users to remove values or hashes from the default module
template configuration. This means you can override some values of the PDK
default template without maintaining your own custom template. To remove a
value, specify the configuration file and setting in your `.sync.yml` file, and
prefix the value you want to remove with the "knockout prefix," `---`

For example, to remove the `bundler_args` value `--without system_tests` from
your Travis CI configuration, specify the Travis CI configuration file,
prefixing the value with the knockout prefix, `---` :

```
.travis.yml:
  bundle_args: -----without system_tests
```

When you run `pdk update` or `pdk convert`, PDK generates the specified
configuration file without the knocked out value. To learn more about
customizing your module template with the `.sync.yml` file, see the
[pdk-template](https://github.com/puppetlabs/pdk-templates)
project. [[PDK-949](https://tickets.puppetlabs.com/browse/PDK-949)]

### Resolved issues

#### PDK exits with a warning if run on an incompatible module

If you run PDK commands, such as `pdk validate` or `pdk test unit`, on a module
that has not been converted for use with PDK, PDK now exits after informing you
that the module needs to be converted. Previously, PDK informed you that the
module was incompatible and then attempted to run the requested command anyway,
with varying success. [[PDK-802](https://tickets.puppetlabs.com/browse/PDK-802)]

#### Parallel fixture downloads no longer cause errors

An issue in `puppetlabs_spec_helper` caused errors with parallel downloads of
fixtures from multiple Git repositories.
[[PDK-1031](https://tickets.puppetlabs.com/browse/PDK-1031)]

#### Rubocop could not be disabled

This release fixes an issue preventing module developers from configuring
`.sync.yml` to disable Rubocop checks.
[[PDK-998](https://tickets.puppetlabs.com/browse/PDK-998)]

#### PDK failed if you tried to validate too many files 

If you were validating a large number of files, PDK failed with a Ruby error.
Now PDK runs the validation in batches so that this doesn't fail.
[[PDK-985](https://tickets.puppetlabs.com/browse/PDK-985)]

#### Running unit tests on Windows attempted to create an invalid directory

When you run `pdk test unit` on Windows, PDK attempts to initialize a test
environment in a `/dev/null` directory, which causes an error Windows. Now
`rspec-puppet` overrides the `/dev/null` values, changing them to `NUL` when
running on Windows. [[PDK-983](https://tickets.puppetlabs.com/browse/PDK-983)]

#### Installing gem dependencies on Windows resulted in an error

When PDK attempted to `bundle install` gem dependencies, an issue in the
`openssl` gem could cause an `SSLError` on Windows. To learn more about the
background of this error, see
[https://bugs.ruby-lang.org/issues/11033](https://bugs.ruby-lang.org/issues/11033)
. This issue is largely resolved for PDK packages, although you might still
encounter it if you use `bundler` commands with PDK and Ruby 2.1.9 on Windows.
[[PDK-802](https://tickets.puppetlabs.com/browse/PDK-802)]

#### Module validation and testing on Windows failed if using Beaker 

This release fixes an issue validating and testing modules using Beaker on
Windows. PDK now packages the Beaker dependencies that require native
compilation. You can use PDK with modules that include Beaker in their Gemfile
without having to alter the module's Gemfile.

The root cause of this issue is that PDK packages cannot always install gems
that include native extensions, which must be compiled before they can be used
by a Ruby application. This release fixes the Beaker issue, but not the root
cause. Gems that require native compilation, but are not part of Beaker's
dependency tree, still require compilation.
[[PDK-950](https://tickets.puppetlabs.com/browse/PDK-950)]

#### Run unit tests from any module directory

The `pdk test unit` command can now be run from any directory in the module.
Previously, this command raised an unhandled exception if you tried to run it
from any directory other than the module root.
[[PDK-926](https://tickets.puppetlabs.com/browse/PDK-926)]

### PDK 1.6.1

#### Improved help output for `pdk test unit --verbose`

The help output for the `--verbose` flag behavior for `pdk test unit` is
improved. The clarified help output now states that the `--verbose` option for
unit testing displays additional information only if used with the `--list`
option, such as `pdk test unit --list --verbose`.
[[PDK-1048](https://tickets.puppetlabs.com/browse/PDK-1048)]

#### `pdk validate` now displays errors from bundled tools

The `pdk validate` command now displays the output from underlying tools if it
encounters an unexpected error.
[[PDK-1053](https://tickets.puppetlabs.com/browse/PDK-1053)]

#### `pdk build` returned an error if it couldn't find Rake

Building the module package in a directory where `./bin/rake` did not yet exist
returned an execution error. The `pdk build` command now creates the Rake
binstub needed to clean up the module prior to packaging.
[[PDK-1061](https://tickets.puppetlabs.com/browse/PDK-1061)]

#### `pdk validate` attempted to validate unit test fixtures

Fixtures downloaded when running `pdk test unit`, which are stored in
`<MODULE>/spec/fixtures`, are now excluded from `pdk validate` runs.
[[PDK-925](https://tickets.puppetlabs.com/browse/PDK-925)]

#### Users could not add files in custom module template subdirectories

This release resolves a bug in the new module template renderer that prevented
users from adding files in nested subdirectories to custom module templates.
[[PDK-906](https://tickets.puppetlabs.com/browse/PDK-906)]

#### `pdk validate` command error handling improved

Improved handling of unexpected errors when parsing the output of `puppet parser
validate` as part of `pdk validate`.
[[PDK-1046](https://tickets.puppetlabs.com/browse/PDK-1046)]

#### PDK returned a confusing error if the module template URL changed

An improved error message is now displayed if you are updating a module and
template does not exist at the URL that PDK expects.
[[PDK-1041](https://tickets.puppetlabs.com/browse/PDK-1041)]

#### PDK reports `rspec-puppet` coverage to the user

PDK now displays the results of an `rspec-puppet` test coverage report, if the
user has enabled coverage reporting in their `rspec-puppet` configuration.
Previously, PDK printed this information to only `STDOUT`.
[[PDK-1051](https://tickets.puppetlabs.com/browse/PDK-1051)]

#### PDK failed if paths were too long in Windows

PDK sometimes encountered an error that a command was too long on Windows. To
reduce the length of the commands that PDK executes, file paths are now sent to
the validator as relative paths.
[[PDK-1045](https://tickets.puppetlabs.com/browse/PDK-1045)]

#### Unit tests could not correctly be run in parallel

This release fixes an issue where the `pdk test unit --parallel` command was not
correctly running unit tests in parallel.
[[PDK-1067](https://tickets.puppetlabs.com/browse/PDK-1067)]

#### Parallel tests on Windows and Ruby 2.1 sometimes failed

When running parallel tests on Windows in Ruby 2.1, a `rspec-puppet` interaction
with `puppetlabs_spec_helper` would sometimes fail while checking the fixture
directory junction. The issue has been fixed in `rspec-puppet`.
[[PDK-1054](https://tickets.puppetlabs.com/browse/PDK-1054)]

#### Corrected PATH environment

This release fixes an issue where PDK subprocesses did not have the correct PATH
environment. This issue would manifest as a "command not found" error when
trying to use `bundle exec` to run a command from a bundled Ruby gem such as
`rspec`. [[PDK-1073](https://tickets.puppetlabs.com/browse/PDK-1073)]

## PDK 1.5

### New features and enhancements

#### Validate and test against specific Puppet versions

You can now test and validate your modules against specific Puppet or PE
versions. This release adds the `--pe-version` and `--puppet-version` options to
the PDK validate and unit test functions. These options validate or run unit
tests against the Puppet version specified or included in the specified PE
version. See the documentation for [validating and testing
modules](pdk_testing.md) for details.
[[PDK-414](https://tickets.puppetlabs.com/browse/PDK-414)]

#### PDK adds a framework option for unit tests

You can now choose which mocking framework PDK uses for running your unit tests.
In a `sync.yml` file in your module, set the `mock_with` setting to either
`:mocha` or `:rspec`. We suggest using the RSpec framework. However, to maintain
compatibility for existing modules, the PDK template defaults to the Mocha
framework. See the [`puppetlabs_spec_helper`
README](https://github.com/puppetlabs/puppetlabs_spec_helper#mock_with) for
details about this setting.
[[PDK-916](https://tickets.puppetlabs.com/browse/PDK-916)]

#### PDK support available for Puppet Enterprise customers

PE customers can now get customer support for PDK version 1.5.0 and newer. To
get help, contact support through the [customer support
portal](https://support.puppet.com/hc/en-us).

#### Ruby 2.5 compatibility added

PDK is now compatible with Ruby version 2.5.

### Resolved issues

#### Legacy code supporting Puppet 4.7 and older dropped

This release removes artifacts and dependencies from the PDK template that
supported Puppet versions less than 4.7.
[[PDK-389](https://tickets.puppetlabs.com/browse/PDK-389)]

#### Some `.sync.yml` settings were ignored by PDK commands

This release fixes a bug where the `pdk convert` and `pdk update` commands did
not respect the `unmanaged` or `delete` keys in the `.sync.yml` file. These
commands now correctly ignore or delete files specified with these keys.
[[PDK-832](https://tickets.puppetlabs.com/browse/PDK-832) ,
[PDK-831](https://tickets.puppetlabs.com/browse/PDK-831)]

## PDK 1.4

The first release of PDK 1.4 was 1.4.1.

### New features and enhancements

#### Module creation interview is simplified

This release removes questions related to Forge use from the `pdk new module`
and `pdk convert`commands. By default, the interview now asks only the questions
required to run validation and unit tests, making the interview process faster
if you don't plan to upload your module to the Forge.

If you do plan to publish your module on the Forge, you can use the
--full-interview option to include all questions.
[[PDK-550](https://tickets.puppetlabs.com/browse/PDK-550)]

#### Update your PDK modules to reflect module template changes

The `pdk update` command updates PDK compatible modules with any changes to the
module template. See the topic about [updating the module
template](pdk_updating_modules.md) for details and usage.
[[PDK-771](https://tickets.puppetlabs.com/browse/PDK-771)]

#### PDK builds module packages

This release adds the `pdk build` command, which builds the module project into
a package that can be uploaded to the Forge. See the [building module
packages](pdk_building_module_packages.md) topic for details and usage
informaiton. [[PDK-748](https://tickets.puppetlabs.com/browse/PDK-748)]

### Resolved issues

#### Security updates for packaged curl and Nokogiri

This release updates the packaged curl library to 7.59.0 and the packaged
Nokogiri version to 1.8.2 for security fixes.

#### PDK validation no longer tries to read `puppet.conf` files

When running Puppet manifest syntax validation, the `pdk validate` command no
longer reads or throws errors on `puppet.conf` files in the default locations
(such as `/etc/puppet/puppet.conf`) on the user's host.
[[PDK-575](https://tickets.puppetlabs.com/browse/PDK-575)]

## PDK 1.3

### New features and enhancements

#### Rakefile is now configurable in `sync.yml`

The PDK template has been modified so that you can add extra requires or imports
to the Rakefile when converting existing modules. To learn how to customize your
module template, see [customizing your
module](customizing_module_config.md).
[[PDK-756](https://tickets.puppetlabs.com/browse/PDK-756)]

#### Test unit command provides detailed information

The `pdk test unit --lis`t command lists the module test files that contain
examples. Add `--verbose` or `-v` to display more information about the examples
in each file. [[PDK-674]](https://tickets.puppetlabs.com/browse/PDK-674)

#### PDK reports what template was used for module creation 

The `pdk new module` command now accepts a full module name, which includes the
Forge user name and the module name, such as `forgeuser-modulename`. Standard
PDK usage is to pass only the short module name with the new module command
(`pdk new module modulename`), but this change offers flexibility.
[[PDK-594](https://tickets.puppetlabs.com/browse/PDK-594)]

#### PDK asks for a module name on new module creation

If you run the `pdk new module` command but don't pass a name for the new
module, PDK asks for the module name in the metadata questionnaire.
[[PDK-671](https://tickets.puppetlabs.com/browse/PDK-671),
[PDK-628](https://tickets.puppetlabs.com/browse/PDK-628)]

#### Convert existing modules to a PDK compatible format

This release adds the `pdk convert` command, which you can use to make your
existing module compatible with PDK . After you convert a module, you can use
all PDK functions with that module, such as creating classes, validating, and
unit testing. See the instructions for [converting](pdk_converting_modules.md#)
modules for detailed information.

### Resolved issues

#### Curl security update

This release updates the curl version included in PDK to 7.57.0. This update is
a security fix. [[PDK-714](https://tickets.puppetlabs.com/browse/PDK-714)]

#### OpenSSL security update

This release updates the `openssl` version included in PDK to 1.0.2m. This
update is a security fix.
[[PDK-667](https://tickets.puppetlabs.com/browse/PDK-667)]

#### Passing a test list to the `pdk test unit` command failed to run any tests

Fixes an issue where no tests would run if you passed the `--tests` option to
`pdk test unit`, because the command did not pass the arguments to the unit test
handler. [[PDK-429](https://tickets.puppetlabs.com/browse/PDK-429)]

### PDK 1.3.1

#### Cached template URL in PDK 1.3.0 upgrades prevented module creation

If you upgraded PDK to version 1.3.0 from a previous installation, an outdated
template URL cached in your answers file could prevent creating or converting
modules. [[PDK-736](https://tickets.puppetlabs.com/browse/PDK-736)]

### PDK 1.3.2

#### PDK exited with a fatal error if the cached template URL was invalid

If the `template-url` value in the PDK answers file was no longer valid, PDK
exited with a fatal error. Now when you create or convert a module, PDK checks
that the `template-url` repository exists. If it does not, PDK warns you, falls
back to the default template, and removes the invalid URL from the answers file.
To update the URL in the PDK answers file, specify the new URL with the
`--template-url` flag.
[[PDK-739](https://tickets.puppetlabs.com/browse/PDK-739)]

## PDK 1.2

### New features and enhancements

#### CLI help is improved

This release adds context to ambiguous help output from `pdk help`.

#### Module creation adds examples and files subdirectories

The `pdk new module` command now creates `./examples` and `./files`
subdirectories in the new module. These directories can contain code examples
and extra files, respectively.

#### PDK validates task metadata

When you run `pdk validate metadata`, PDK validates both module and task
metadata files.

#### PDK can create tasks in modules

Tasks allow you to perform ad hoc actions for on-demand infrastructure change.
When you create a module, PDK creates an empty `./tasks`folder. When you create
a task, PDK creates template files for the task (`<TASK>.sh`) and the task
metadata (`<TASK>.json`). See the [writing
tasks](https://puppet.com/docs/bolt/0.x/writing_tasks_and_plans.html) topic for
more information about tasks and the [create a task](pdk_creating_modules.md#create-a-task)
topic for how to create a task with PDK.

### Resolved issues

#### Git version in PDK did not install some dependencies on Windows  

The version of Git included in the PDK packages did not work correctly with
Bundler on Windows, so gem dependencies specified in a module's Gemfile with a
Git source were not correctly installed. This release fixes this issue.

#### Running PDK commands on Windows 7 failed

Using PDK on Windows 7 resulted in access errors and Ruby failure. This release
fixes the issue

#### Validation stopped if errors were encountered

The `pdk validate` command now runs all possible validators, even if one of them
reports an error.

#### Validation failed to validate using Windows paths

This release fixes an issue where `puppet-lint` was not properly escaping
`bundle` commands in Windows. We've added a note to the help text in PDK, and
the root cause will be fixed in a `puppet-lint` release to be included in PDK.

## PDK1.1

### New features and enhancements

#### Improved error output

-   The `pdk test unit` provides improved error messages when unit tests fail.

-   Errors from `spec_prep` and `spec_clean` failures are improved to provide
    only relevant error information.

-   If you try to create a class that already exists, PDK gives an error instead
    of a fatal error.


#### Operating system question added to new module interview

The module creation interview now asks which operating systems your module
supports. You can select supported operating systems from an interactive dialog
menu.

#### PDK can generate defined types

PDK can now generate defined types in a module. Usage is similar to the class
generation: `pdk new defined_type <NAME>`. For usage details, see [creating
modules](pdk_creating_modules.md).

### Resolved issues

#### Installing PDK in a non-default location caused an error

Installing PDK in a non-default location caused an error condition because the
template URL was saved into the answer file. With this release, the template URL
is no longer saved into the answer file.

#### Modules generated with PDK depended on `puppetlabs-stdlib` module by default

This release removes an unnecessary dependency on the `puppetlabs-stdlib` module
in a newly generated module's `metadata.json.`

#### PDK package installation created unnecessary directories

PDK package installation created an unnecessary directory: `/etc/puppetlabs` on
Linux, `/private/etc/puppetlabs` on Mac OS X, and `C:\Documents and
Settings\$user\Application Data\PuppetLabs` on Windows. These directories are no
longer created on installation.

#### Generated `.gitattributes` file caused Ruby validation failure

An error in the generated `gitattributes` file caused Ruby style checking with
Rubocop to fail. Now PDK configures `.gitattributes` to correctly match
end-of-line behavior with the recommended Git attribute configuration, always
requiring `LF` line ends.

#### PDK module template contained a TravisCI configuration error

An error in the module template's TravisCI configuration (`.travis.yml`) caused
TravisCI to not run any CI jobs. This was because the environment variable
`CHECK`, which specifies what each TravisCI build job should do, was undefined.
TravisCI now properly runs the unit tests and validators.

#### PDK was not added to PATH in some shells

PDK was not automatically added to the PATH in some shells, including Debian.
This issue is now resolved. However, if you are using ZShell on Mac OS X , you
must add the PATH manually by adding the line `eval $(/usr/libexec/path_helper
-s)` to the ZShell resource file (`~/.zshrc`).

#### PDK conflicted with the Puppet 5 gem

If Puppet 5 and PDK were both specified in a Bundler Gemfile, Puppet code within
PDK conflicted with the Puppet 5 gem, causing an unhandled exception. This
exception no longer occurs.

#### PDK did not work correctly with PowerShell 2

This release improves the PowerShell integration so that PDK works on PowerShell
2, the standard version on Windows 7.

## PDK 1.0

### New features

#### PDK initial release

This is the first major release of Puppet Development Kit (PDK).

-   Generates modules with a complete module skeleton, metadata, and README
    template.

-   Generates classes.

-   Generates unit test templates for classes.

-   Validates `metadata.json` file.

-   Validates Puppet code style and syntax.

-   Validates Ruby style and syntax.

-   Runs RSpec unit tests on modules and classes.

