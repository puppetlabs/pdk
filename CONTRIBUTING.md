# Contributing

Post to [puppet-users@groups.google.com](https://groups.google.com/forum/#!forum/puppet-users) for questions. Error reports and patches welcome in this repo!

# Running from source

In cases where `pdk` needs to run in a working directory outside the cloned repository, either set `BUNDLE_GEMFILE` to the pdk's Gemfile location, or install and use the [binstubs of bundler](http://bundler.io/v1.15/bundle_binstubs.html), which are small proxy binaries, that set up the environment for running the tool.

```
# assuming ~/bin is already on your path:
$ bundle binstubs pdk --path ~/bin
```

Bug reports and pull requests are welcome on GitHub at https://github.com/puppetlabs/pdk/issues.

# Running tests

pdk has the following testing rake tasks

## spec

Run unit tests.

## rubocop

Run ruby style checks. Use `rake rubocop:auto_correct` to fix the easy ones.

## acceptance:local

Run acceptance tests on the current pdk code. These tests are executed on commits and pull requests to this repo using both travis and appveyor.

## acceptance:package

Run acceptance tests against a package install. This task is for Puppet's packaging CI, and contributors outside of Puppet, Inc. don't need to worry about executing it. It uses [beaker](https://github.com/puppetlabs/beaker) to provision a VM, fetch and install a pdk installation package, and then run the acceptance tests on that VM.
It requires some environment variables to be set in order to specify what beaker will set up:

Environment Variable | Usage
---------------------|------
**SHA** | The SHA or tag of a package build i.e. the folder name on the build server that packages will be found in.
**TEST_TARGET** | A beaker-hostgenerator string for the OS of the VM you want to test on e.g. _redhat7-64workstation._ or _windows2012r2-64workstation._ (The period character after workstation is required by beaker-hostgenerator).
**BUILD_SERVER** | (Only required if the tests will run on a Windows VM). The hostname of the build server that hosts packages. A Puppet JIRA ticket ([BKR-1109](https://tickets.puppetlabs.com/browse/BKR-1109)) has been filed to update beaker so this would never be required.

On completion of this testing task, the results from the VM will be available in a folder named _archive_.

# Release Process

1. Bump the version in `lib/pdk/version.rb`.
1. In a clean checkout of master, run `bundle exec rake changelog`.
1. Edit PR titles and tags, until `bundle exec rake changelog` output makes sense.
1. Commit and PR the changes.
1. When the PR is merged, get a clean checkout of the merged commit, and run `bundle exec rake release[upstream]` (where "upstream" is your local name of the puppetlabs remote)
1. Profit!
1. Update `lib/pdk/version.rb` with `x.y.z.pre` version bump, commit, and PR to prepare for next release.
