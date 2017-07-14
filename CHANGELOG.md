# Changelog

All notable changes to this project will be documented in this file.


## [v0.4.0](https://github.com/puppetlabs/pdk/tree/v0.4.0) (2017-07-14)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.3.0...v0.4.0)

**Implemented enhancements:**

- \(SDK-299\) Check metadata.json syntax before linting [\#133](https://github.com/puppetlabs/pdk/pull/133) ([rodjek](https://github.com/rodjek))
- \(SDK-305\) Answer file to cache module interview answers, template-url etc [\#132](https://github.com/puppetlabs/pdk/pull/132) ([rodjek](https://github.com/rodjek))
- \(SDK-296\) Allow target selection for the metadata validator [\#124](https://github.com/puppetlabs/pdk/pull/124) ([rodjek](https://github.com/rodjek))

**Fixed bugs:**

- \(SDK-298\) Handle exception raised when an invalid report format is specified on the CLI [\#125](https://github.com/puppetlabs/pdk/pull/125) ([rodjek](https://github.com/rodjek))

## [v0.3.0](https://github.com/puppetlabs/pdk/tree/v0.3.0) (2017-06-29)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.2.0...v0.3.0)

**Implemented enhancements:**

- \(MAINT\) Add support for stacktrace to Report::Event class [\#112](https://github.com/puppetlabs/pdk/pull/112) ([scotje](https://github.com/scotje))
- \(MAINT\) Various CLI::Exec improvements and updates [\#111](https://github.com/puppetlabs/pdk/pull/111) ([scotje](https://github.com/scotje))
- \(SDK-148\) Add "test unit --list" [\#107](https://github.com/puppetlabs/pdk/pull/107) ([james-stocks](https://github.com/james-stocks))
- \(SDK-137\) Add puppet syntax validation [\#105](https://github.com/puppetlabs/pdk/pull/105) ([bmjen](https://github.com/bmjen))
- \(SDK-285\) Add --auto-correct flag to validators that support it [\#104](https://github.com/puppetlabs/pdk/pull/104) ([rodjek](https://github.com/rodjek))
- \(SDK-284\) Add guidance for users during new module interview [\#103](https://github.com/puppetlabs/pdk/pull/103) ([rodjek](https://github.com/rodjek))
- \(SDK-147\) Add 'test unit' runner and basic output formatting [\#98](https://github.com/puppetlabs/pdk/pull/98) ([scotje](https://github.com/scotje))

**Fixed bugs:**

- \(SDK-297\) Fixes writing reports to a file [\#119](https://github.com/puppetlabs/pdk/pull/119) ([bmjen](https://github.com/bmjen))
- \(SDK-290\) Make sure that all usernames are processed when creating a new module [\#108](https://github.com/puppetlabs/pdk/pull/108) ([austb](https://github.com/austb))
- \(SDK-277\) Exit cleanly if pdk commands are run outside of a module [\#100](https://github.com/puppetlabs/pdk/pull/100) ([rodjek](https://github.com/rodjek))

## [v0.2.0](https://github.com/puppetlabs/pdk/tree/v0.2.0) (2017-06-21)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.1.0...v0.2.0)

**Implemented enhancements:**

- \(SDK-137\) Adds Puppet Parser syntax validation [\#94](https://github.com/puppetlabs/pdk/pull/94) ([bmjen](https://github.com/bmjen))
- \(SDK-274\) Adds --version option [\#90](https://github.com/puppetlabs/pdk/pull/90) ([bmjen](https://github.com/bmjen))
- \(SDK-244\) Add rubocop validation subcommand [\#75](https://github.com/puppetlabs/pdk/pull/75) ([rodjek](https://github.com/rodjek))
- \(maint\) Add hints for gem installation [\#74](https://github.com/puppetlabs/pdk/pull/74) ([DavidS](https://github.com/DavidS))
- \(SDK-240\) Adds puppet-lint validation subcommand [\#71](https://github.com/puppetlabs/pdk/pull/71) ([bmjen](https://github.com/bmjen))
- \(SDK-261\) Manage basic bundler operations for module dev [\#62](https://github.com/puppetlabs/pdk/pull/62) ([scotje](https://github.com/scotje))
- \(SDK-232\) Add operatingsystem\_support defaults [\#58](https://github.com/puppetlabs/pdk/pull/58) ([DavidS](https://github.com/DavidS))

**Fixed bugs:**

- pdk expects missing git binaries [\#61](https://github.com/puppetlabs/pdk/issues/61)
- \(maint\) avoid interfering with local ruby configs [\#86](https://github.com/puppetlabs/pdk/pull/86) ([DavidS](https://github.com/DavidS))
- \(SDK-262\) Populate default metadata to match interview defaults [\#63](https://github.com/puppetlabs/pdk/pull/63) ([rodjek](https://github.com/rodjek))
- \(maint\) nokogiri: avoid versions without ruby 2.1 support [\#60](https://github.com/puppetlabs/pdk/pull/60) ([DavidS](https://github.com/DavidS))

## [v0.1.0](https://github.com/puppetlabs/pdk/tree/v0.1.0) (2017-06-05)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/2be9329bed4715c888f273814b99f2cf37ee9341...v0.1.0)

**Implemented enhancements:**

- \(maint\) update Contributing section [\#56](https://github.com/puppetlabs/pdk/pull/56) ([DavidS](https://github.com/DavidS))
- \(SDK-197\) Add 'new class' generator command [\#48](https://github.com/puppetlabs/pdk/pull/48) ([rodjek](https://github.com/rodjek))
- \(SDK-201\) Add 'new module' generator command [\#41](https://github.com/puppetlabs/pdk/pull/41) ([rodjek](https://github.com/rodjek))
- \(maint\) make debug output optional [\#40](https://github.com/puppetlabs/pdk/pull/40) ([rodjek](https://github.com/rodjek))
- \(maint\) Print help for 'new' command if no type provided [\#35](https://github.com/puppetlabs/pdk/pull/35) ([rodjek](https://github.com/rodjek))
- \(SDK-214\) Add gettext and externalize strings [\#32](https://github.com/puppetlabs/pdk/pull/32) ([scotje](https://github.com/scotje))
- \(SDK-178\) interactive license and module name query [\#30](https://github.com/puppetlabs/pdk/pull/30) ([DavidS](https://github.com/DavidS))
- \(SDK-200\) Add user interview for `new module` info gathering [\#26](https://github.com/puppetlabs/pdk/pull/26) ([whopper](https://github.com/whopper))
- \(maint\) Replace --report-\* options with --format. [\#24](https://github.com/puppetlabs/pdk/pull/24) ([whopper](https://github.com/whopper))
- \(SDK-191\) Allow validators and targets as arguments rather than options [\#22](https://github.com/puppetlabs/pdk/pull/22) ([whopper](https://github.com/whopper))
- \(SDK-185\) Include the command in usage help output [\#19](https://github.com/puppetlabs/pdk/pull/19) ([james-stocks](https://github.com/james-stocks))

**Fixed bugs:**

- \(maint\) use correct basedir for windows execs [\#51](https://github.com/puppetlabs/pdk/pull/51) ([DavidS](https://github.com/DavidS))
- \(maint\) Update pdk.gemspec to not depend on git to assign files. [\#27](https://github.com/puppetlabs/pdk/pull/27) ([scotje](https://github.com/scotje))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*