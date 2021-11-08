# PDK release notes

New features, enhancements, and resolved issues for the PDK 2.x release series.

## PDK 2.3.0
### Resolved issues

Fixes a compatibility issue with psych gem dependency [puppetlabs/pdk#1143](https://github.com/puppetlabs/pdk/issues/1143)

## PDK 2.2.0

### New features and enhancements

The PDK entry point is now Ruby 2.5, up from Ruby 2.4. This change should be transparent to users as the available Ruby versions are unchanged.

Support added for OSX 11, Debian 11, Fedora 32 & 34

A project level setting containing a list of ignored files or patterns for use with `pdk validate` [puppetlabs/pdk#1114](https://github.com/puppetlabs/pdk/pull/1114)

Bump `json_pure` gem to ~> 2.5.1 on Ruby >= 2.7 [puppetlabs/pdk#1124](https://github.com/puppetlabs/pdk/pull/1124)

### Resolved issues
Prevent errors when choosing not to set forge token prior to running `pdk release` [puppetlabs/pdk#1121](https://github.com/puppetlabs/pdk/pull/1121)

Set `skip_branch_with_pr` to true by default in appveyor.yml template [puppetlabs/pdk-templates#442](https://github.com/puppetlabs/pdk-templates/pull/442)

Run validation steps prior to the matrix build [puppetlabs/pdk-templates#441](https://github.com/puppetlabs/pdk-templates/pull/441)

## PDK 2.1.1

### New features and enhancements

#### Use latest Facter version in GHActions Spec Test Template

The Github Actions `spec.yml` workflow now sets the `FACTER_GEM_VERSION` ENV var. See [puppetlabs/pdk-templates#439](https://github.com/puppetlabs/pdk-templates/pull/439).

#### New parameters added in `.gitlab-ci.yml` template

See [puppetlabs/pdk-templates#436](https://github.com/puppetlabs/pdk-templates/pull/436), [puppetlabs/pdk-templates#434](https://github.com/puppetlabs/pdk-templates/pull/434).

#### Backtrace from spec tests cleaned up

The verbosity of the backtrace from spec test failures has been scaled back to ensure the relevant info is easier to read. [puppetlabs/pdk-templates#431](https://github.com/puppetlabs/pdk-templates/pull/431).

#### Added EditorConfig template

See [puppetlabs/pdk-templates#428](https://github.com/puppetlabs/pdk-templates/pull/428).

### Resolved issues

#### Resolved issue with ACCESS_DENIED error on Win Github Actions

Fixes an issue on Windows Server 2016, 2019 instances on Github Actions where child processes were unable to spawn.
See [puppetlabs/pdk#1084](https://github.com/puppetlabs/pdk/pull/1084).

#### Multiple issues resolved in `pdk release`

Fix for an issue where the changelog top most version did not match the version in `metadata.json`.

`pdk release` can now handle the scenario where no Forge token is provided.

See [puppetlabs/pdk#1088](https://github.com/puppetlabs/pdk/pull/1088).

## PDK 2.1

### New features and enhancements

#### Add `pdk env` subcommand

Adds an experimental `pdk env` subcommand. Use `pdk env` to print the environment variables that PDK is currently using (https://github.com/nkanderson).

### Resolved issues

#### `--verbose` option broken for `pdk new defined_type`

Fixes an issue where the `--verbose` option would not work with the `pdk new defined_type` command. See [ddfreyne/cri#103](https://github.com/ddfreyne/cri/issues/103).

#### PDK output scrollback in VS Code limited

Resolves a scrollback issue when using PDK in the integrated terminal of VS Code by disabling ANSICON on Windows.

### Template changes and fixes

* Relocated the`inventory.yaml` file used by Litmus. This prevents accidental execution of acceptance tests in production systems. (https://github.com/pmcmaw)
* Removed Win32 gems from the Gemfile. These have been included in Puppet since version 5. (https://github.com/da-ar)
* Added Puppet 7 tests to .gitlab-ci.yml (https://github.com/silug)

## PDK 2.0

### Backwards incompatible changes

#### Removed support for Puppet 4.x and Ruby \< 2.4.0

The PDK gem now requires at least Ruby 2.4.0. PDK OS-native packages no longer
include Puppet 4.x or the Ruby 2.1.9 runtime environment. If your workflow
requires you to work with Puppet 4.x code, you can continue to use the latest
PDK 1.x release, however support for the 1.x series might end soon.

#### New default mocking framework

The default mocking framework for RSpec tests has been updated to `rspec-mocks`.
Previously `puppetlabs_spec_helper` was loading both `rspec-mocks` and `mocha`.
This leads to confusing inconsistencies in unit tests. We've been recommending
`rspec-mocks` as the preferred library for some time. If your test suite is not
yet ready for this step, remove the default value by setting `mock_with: ~`
(YAML's nil value) in your `.sync.yml` file to get the PDK 1.x behavior.
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
templates repo you might need to use `pdk convert --default-template` to switch
back to the default branch.

Similarly, the `--puppet-dev` version selection flag now pulls from the `main`
branch of the official Puppet source code repository.

#### Better error messages for `pdk release publish` failures

The `pdk release publish` command now surfaces the underlying Forge error messages
if the module upload step fails. (https://github.com/michaeltlombardi)

### Resolved issues

#### Improved Facter compatibility

The PDK gem can now be activated alongside Facter 4.x. (https://github.com/GabrielNagy)

#### Removal of harmful/offensive terminology

Several instances of inappropriate, harmful, or insensitive terminology have been removed
from documentation, code examples, etc. Please open an issue or pull request if you
find additional instances.

### Template Changes and Fixes

 * To set up code for the default Ruby 2.7 behavior, the Rubocop rule
 `Style/BracesAroundHashParameters` is now disabled by default.
 (https://github.com/alexjfisher)

 * Improved flexibility of Appveyor configuration by providing a `remove_includes`
 option to manipulate the jobs to be run. (https://github.com/sheenaajay)

 * Enabled VSCode's "Remote Containers" plugin to allow running all the backend tooling
 in a remote container, instead of requiring a local PDK install. (https://github.com/silug)

 * Fixed setting `strict_variables` to false. (https://github.com/cdenneen)

 * Updated GitLab CI config to new schema. (https://github.com/silug)

 * Updated `pdk build` to automatically exclude `.puppet-lint.rc` and `.sync.yml`.
 (https://github.com/silug)

 * Added an empty, commented `.sync.yml` to new modules to help folks jumpstart the
 customization process. (https://github.com/silug)

 * Added ability to override GitLab CI global defaults in jobs. (https://github.com/cdenneen)

 * Added Gitpod.io support to modules. (https://github.com/logicminds)

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
