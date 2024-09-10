# PDK release notes

New features, enhancements, and resolved issues for PDK.

## PDK 3.3.0

### New features and enhancements

* Name validation now skipped for controlrepo's
* The PDK has been updated to use the `modulebuilder` gem in place of duplicated code within the PDK.
* Support for Debian 11 and 12 has been extended to AARCH64 with new packages built
* Support for Ubuntu 18.04 to 23.04 has been extended to AARCH64 with new packages built
* Support for RedHat 9 has been extended to AARCH64 with new packages built
* Support for Mac OsX 13 has been extended to arm64 with new packages built
* Windows 2019 package is now being tested on Windows 11 to ensure support

### Bug Fixes

* The childprocess gem has been updated and a patch for it has been removed.
* `pdk test --list` has been updated to account for a change in how information is passed back to it.

### Template Changes

* Updated to require `facterdb` 1.26 or newer
* Bolt-related files added to the .gitignore default paths
* `puppetlabs_sec_help` pinned to 7.3 or newer and `.rspec.erb` removed to account
* Pin added for `rexml` to account for Windows issues
* `deep_merge` updated to require 1.2.2 or newer
* Config extras handling added back into the Rakefile
* `.vendor` added to .gitignore
* `facterdb` repinned to ~> 2.1 and `rspec-puppet-facts`to ~> 4.0

## PDK 3.2.0

### Deprecations

* Analytics have been removed from the code
* Support has been officially withdrawn for Debian 9 and Redhat 6.

### New features and enhancements

* Support has been added and packages are now being built for Debian 12 and Mac OSX 13.
* While not possessing an explicit package Windows 11 is now being verified as supported.

### Template Changes

* CFPropertyList has been pinned on Windows
* Fix implemented so that .sync.yml will properly overide Rubocop rules
* Duplicate gems have been removed

## PDK 3.1.0

### New features and enhancements

* Executable templates are now supported
* `pdk convert` and `pdk update`can now work in a ControlRepo context

### Template Changes

* The templates have been updated to allow Rubocop rules to be overriden.
* CFPropertyList has been added as a pinned dependency on Windows.
* Our Rubocop pin has been increased to `1.50.0`.
* The codecov gem has been removed.
* The archived ruby vscode extension has been replaced.

## PDK 3.0.1

### New features and enhancements

* Updated various dependencies
* Added stricter puppetlabs_spec_helper dependency
* Minor adjustments to our documentation

## PDK 3.0.0

> PDK 3.0 is a backwards incompatible release.

### New features and enhancements

* Ruby 3.2.2 is now the default version of Ruby.
* Puppet 8 is now the default version of Puppet.
* PDK no longer relies on PowerShell, you are able to use PDK from any terminal that honours your PATH variable.
* As of this release, PDK now only includes the latest Puppet versions available at the time of build. This siginficantly reduces the package size and improves performance.
* The `bundle` command is no longer `experimental`.
* PDK now properly respects the `verbose` option when utilizing format options for unit testing.
* PDK now supports the `operatingsystem_support` parameter from `answers.json`.

### Deprecations

* The `--pe-version` flag has been deprecated. It will continue to work but we advise moving to `--puppet-version` given that this flag will be removed in a future release.
* The deprecated `module` command has now been removed.
* The deprecated `config` command has now been removed.
* The experimental `console` command has been removed from this release.
