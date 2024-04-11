# PDK release notes

New features, enhancements, and resolved issues for PDK.

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
