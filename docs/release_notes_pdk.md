# PDK release notes

New features, enhancements, and resolved issues for the PDK 2.x release series.

## PDK 2.0

### Backwards incompatible changes

#### Removed support for Puppet 4.x and Ruby \< 2.4.0

The PDK gem now requires at least Ruby 2.4.0. PDK OS-native packages no longer
include Puppet 4.x or the Ruby 2.1.9 runtime environment. If your workflow
requires you to work with Puppet 4.x code, you may continue to use the latest
PDK 1.x release, however support for the 1.x series may end soon.

#### New default mocking framework

The default mocking framework for RSpec tests has been updated to `rspec-mocks`.
Previously `puppetlabs_spec_helper` was loading both `rspec-mocks` and `mocha`.
This leads to confusing inconsistencies in unit tests. We have been recommending
`rspec-mocks` as the preferred library for some time. If your test suite is not
yet ready for this step, remove the default value through setting `mock_with: ~`
(YAML's nil value) in you `.sync.yml` to get the PDK 1.x behavior.
(https://github.com/DavidS)

### New features and enhancements

#### Added ability to generate new facts

Added the `pdk new fact` command to generate new custom facts in a module.
(https://github.com/logicminds)

#### Added ability to generate new functions

Added the `pdk new function` command to generate new functions in a module.
(https://github.com/logicminds)

#### Added AIX option to new module interview options

Added AIX to OS compatibility picker during the guided interview for
`pdk new module`. (https://github.com/logicminds)

#### Set Forge API token via environment variable

You can now set your Forge API token via the `PDK_FORGE_TOKEN` environment variable.
(https://github.com/logicminds)

#### Renamed default branches to `main`

The default branches for PDK and the PDK templates repositories have been renamed
to `main`, and the PDK's template-related code has been updated to reflect this
change. If you have a module that was manually pinned to the `master` branch of the
templates repo you may need to use `pdk convert --default-template` to switch
back to the default branch.

Similarly, the `--puppet-dev` version selection flag will now pull from the `main`
branch of the official Puppet source code repository.

#### Better error messages for `pdk release publish` failures

The `pdk release publish` command will now surface the underlying Forge error messages
if the module upload step fails. (https://github.com/michaeltlombardi)

### Resolved issues

#### Improved facter compatibility

The PDK gem can now be activated alongside Facter 4.x. (https://github.com/GabrielNagy)

#### Removal of harmful/offensive terminology

Several instances of inappropriate, harmful, or insensitive terminology have been removed
from documentation, code examples, etc. Please open an issue or pull request if you
find additional instances.

### Template Changes and Fixes

 * To set up code for the default Ruby 2.7 behaviour, the Rubocop rule
 `Style/BracesAroundHashParameters` is now disabled by default.
 (https://github.com/alexjfisher)

 * Improved flexibility of Appveyor configuration by providing a `remove_includes`
 option to manipulate the jobs to be run. (https://github.com/sheenaajay)

 * Enabled VSCode's "Remote Containers" plugin to allow running all the backend tooling
 in a remote container, instead of requiring a local PDK install. (https://github.com/silug)

 * Fixed setting `strict_variables` to false. (https://github.com/cdenneen)

 * Updated Gitlab CI config to new schema. (https://github.com/silug)

 * Updated `pdk build` to automatically exclude `.puppet-lint.rc` and `.sync.yml`.
 (https://github.com/silug)

 * Added an empty, commented `.sync.yml` to new modules to help folks jumpstart the
 customisation process. (https://github.com/silug)

 * Made Gitlab CI global defaults overridable in jobs. (https://github.com/cdenneen)

 * Add Gitpod.io support to modules. (https://github.com/logicminds)

 * Implemented Puppet's public Litmus runners in Github Actions workflows. This provides
 immediate feedback on testing through running the full test suite against ephemeral VMs
 on each PR update. (https://github.com/DavidS, https://github.com/ekohl)

 * Travis config now allows setting the chosen distributions per Puppet collection for
 acceptance tests. (https://github.com/adrianiurca)

 * Updated template-configured Rubocop to current version; updated default cops; updated
 target Ruby version to 2.4. (https://github.com/tuxmea, https://github.com/DavidS)

 * Updated default Ruby version for static analysis steps run in Appveyor.
 (https://github.com/pmcmaw)

 * Added a Github workflow to run module release prep on-demand or on a schedule.
 (https://github.com/carabasdaniel, https://github.com/pmcmaw, https://github.com/ekohl)

 * Added an optional step to run Litmus on Gitlab CI. (https://github.com/cdenneen)

 * Fixed new object templates to pass validation and unit tests after initial generation.
 (https://github.com/DavidS, https://github.com/cdenneen)

 * Removed Puppet 5.x from default Travis and Appveyor configs.
 (https://github.com/carabasdaniel, https://github.com/cdenneen)

