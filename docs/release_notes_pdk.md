# PDK release notes

New features, enhancements, and resolved issues for PDK.

## PDK 3.4.0

### Deprecations

* Support has been removed for `SLES 12` and packages for it are no being longer built.

### New features and enhancements

* The in built `forge upload` functionality has been replaced with a call to the `puppet_forge` gem.
* `json-schema` dependency updated to `~> 5.0` in order for it to be kept it in line with the wider Puppet products.
* Support for `RedHat 8` has been extended to `AARCH64` with new packages built.

### Bug Fixes

* A parser swap to `JSON::Pure` has been removed from the `metadata_syntax_validator` changing the format of the output. This was required due to the parser used no being longer included within either the `json` or `json_pure` gems.
* Removed the dependency on the `json_pure` gem as it is no longer necesary with `json` added as a default ruby gem.
* Deprecated call `Gem::Platform.match()` replaced with the modern `Gem::Platform.match_spec?` within `puppet_version.rb`.
* Updated `vendored_file.rb` to use vendored cert files and `VERIFY_PEER` with `NET::HTTP` on Windows machines.
* The above change to `vendored_file.rb` has been updated to set `http.ca_file` rather than `http.cert`.
* The PDK spinner has been updated on Windows to be more consistent, with tick marks now being given upon success.

### Runtime Changes

* The version of the `git` gem bundled within the runtime has been set to `2.39.4`.
* The `json_pure` gem has been removed from the runtime.
* The `puppet_forge` gem has been added to the runtime pinned to `5.0.4`, with the following dependencies also added:
  * Dependency `faraday` pinned to `2.12.0`.
  * Dependency `faraday-follow_redirects` pinned to `0.3.0`.
  * Dependency `faraday-net_http` pinned to `3.3.0`.
  * Dependency `semantic_puppet` pinned to `1.1.0`.
  * Dependency `minitar` already present, pin kept at `0.9`.

### Template Changes

* The `puppet_blacksmith` gem has been added to the templates, pinned to `~> 7.0`.
* The `puppetlabs_spec_helper` gem has been repinned to `~> 8.0`.
* Default `lint` configuration has been updated to match that within `puppetlabs_spec_helper`. Notation added to help ensure they are kept in sync.

## PDK 3.3.0

### New features and enhancements

* Name validation now skipped for controlrepo's
* The PDK has been updated to use the `modulebuilder` gem in place of duplicated code within the PDK.
* Support for Debian 11 and 12 has been extended to AARCH64 with new packages built
* Support for Ubuntu 18.04 to 24.04 has been extended to AARCH64 with new packages built
* Support for RedHat 9 has been extended to AARCH64 with new packages built
* Support for Mac OsX 13 has been extended to arm64 with new packages built
* Windows 2019 package is now being tested on Windows 11 to ensure support

### Bug Fixes

* The childprocess gem has been updated and a patch for it has been removed.
* `pdk test --list` has been updated to account for a change in how information is passed back to it.

### Template Changes

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
