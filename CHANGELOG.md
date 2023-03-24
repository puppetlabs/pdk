<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v2.7.1](https://github.com/puppetlabs/pdk/tree/v2.7.1) - 2023-03-24

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v2.7.0...v2.7.1)

## [v2.7.0](https://github.com/puppetlabs/pdk/tree/v2.7.0) - 2023-03-14

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v2.6.1...v2.7.0)

### Added

- (CONT-694) Bump PDK Template Version [#1216](https://github.com/puppetlabs/pdk/pull/1216) ([chelnak](https://github.com/chelnak))
- (CONT-370) Remove i18n support [#1211](https://github.com/puppetlabs/pdk/pull/1211) ([chelnak](https://github.com/chelnak))
- Add Puppet validator for plans [#1207](https://github.com/puppetlabs/pdk/pull/1207) ([jay7x](https://github.com/jay7x))

### Fixed

- (CONT-722) Patch pe to puppet mapping [#1221](https://github.com/puppetlabs/pdk/pull/1221) ([chelnak](https://github.com/chelnak))
- (GH-1210) Require uri [#1220](https://github.com/puppetlabs/pdk/pull/1220) ([chelnak](https://github.com/chelnak))
- (CONT-720) Fix default version selection [#1219](https://github.com/puppetlabs/pdk/pull/1219) ([chelnak](https://github.com/chelnak))
- (CONT-719) Require JSON gem [#1218](https://github.com/puppetlabs/pdk/pull/1218) ([chelnak](https://github.com/chelnak))
- (CONT-669) Use bundle info command [#1215](https://github.com/puppetlabs/pdk/pull/1215) ([chelnak](https://github.com/chelnak))

## [v2.6.1](https://github.com/puppetlabs/pdk/tree/v2.6.1) - 2023-01-26

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v2.6.0...v2.6.1)

## [v2.6.0](https://github.com/puppetlabs/pdk/tree/v2.6.0) - 2023-01-17

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v2.5.0...v2.6.0)

### Added

- (CONT-422) PDK v2.6.0 [#1195](https://github.com/puppetlabs/pdk/pull/1195) ([chelnak](https://github.com/chelnak))

### Fixed

- Fixing deprecated message on api_types.rb [#1177](https://github.com/puppetlabs/pdk/pull/1177) ([davidsandilands](https://github.com/davidsandilands))

## [v2.5.0](https://github.com/puppetlabs/pdk/tree/v2.5.0) - 2022-05-17

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v2.4.0...v2.5.0)

## [v2.4.0](https://github.com/puppetlabs/pdk/tree/v2.4.0) - 2022-02-07

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v2.3.0...v2.4.0)

### Fixed

- (PDK-1758) supplement `in_module_root` with check for `metadata.json` [#1154](https://github.com/puppetlabs/pdk/pull/1154) ([da-ar](https://github.com/da-ar))

## [v2.3.0](https://github.com/puppetlabs/pdk/tree/v2.3.0) - 2021-10-21

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v2.2.0...v2.3.0)

### Fixed

- Account for Psych API changes [#1147](https://github.com/puppetlabs/pdk/pull/1147) ([binford2k](https://github.com/binford2k))
- (MAINT) Update install.md w/ supported OSs; release note fixes [#1138](https://github.com/puppetlabs/pdk/pull/1138) ([sanfrancrisko](https://github.com/sanfrancrisko))
- (maint) Docs for 2.2.0 [#1134](https://github.com/puppetlabs/pdk/pull/1134) ([da-ar](https://github.com/da-ar))

## [v2.2.0](https://github.com/puppetlabs/pdk/tree/v2.2.0) - 2021-08-02

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v2.1.1...v2.2.0)

### Added

- (GH-1118) Add ability to skip validating files [#1114](https://github.com/puppetlabs/pdk/pull/1114) ([jpogran](https://github.com/jpogran))

### Fixed

- (GH-1113) (GH-917) Fix forge-token handling [#1121](https://github.com/puppetlabs/pdk/pull/1121) ([sanfrancrisko](https://github.com/sanfrancrisko))

### Other

- (maint) Update beaker-hostgenerator to support newer platforms [#1125](https://github.com/puppetlabs/pdk/pull/1125) ([da-ar](https://github.com/da-ar))
- (GH-1115) Bump `json_pure` to `~> 2.5.1` on Ruby `>= 2.7` [#1124](https://github.com/puppetlabs/pdk/pull/1124) ([sanfrancrisko](https://github.com/sanfrancrisko))

## [v2.1.1](https://github.com/puppetlabs/pdk/tree/v2.1.1) - 2021-06-22

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v2.1.0...v2.1.1)

### Fixed

- (PDK-1085) Fail gracefully when no unit tests available [#1096](https://github.com/puppetlabs/pdk/pull/1096) ([sanfrancrisko](https://github.com/sanfrancrisko))
- (GH-1090) Verify the changelog top most version matches the metadata version [#1088](https://github.com/puppetlabs/pdk/pull/1088) ([carabasdaniel](https://github.com/carabasdaniel))
- (GH-1083) Bump childprocess to '~> 4.0.0'; Disable @process.leader [#1084](https://github.com/puppetlabs/pdk/pull/1084) ([sanfrancrisko](https://github.com/sanfrancrisko))
- (puppetlabs/devx#15) `pdk validate` overview ref doc [#1071](https://github.com/puppetlabs/pdk/pull/1071) ([sanfrancrisko](https://github.com/sanfrancrisko))

## [v2.1.0](https://github.com/puppetlabs/pdk/tree/v2.1.0) - 2021-04-06

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v2.0.0...v2.1.0)

### Added

- (PF-2332) Add `pdk env` subcommand [#957](https://github.com/puppetlabs/pdk/pull/957) ([nkanderson](https://github.com/nkanderson))

### Fixed

- (Docs)Updating docs metadata [#961](https://github.com/puppetlabs/pdk/pull/961) ([hestonhoffman](https://github.com/hestonhoffman))

## [v2.0.0](https://github.com/puppetlabs/pdk/tree/v2.0.0) - 2021-02-24

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.18.1...v2.0.0)

### Added

- (IAC-1438) - Removal of Inappropriate Terminology [#945](https://github.com/puppetlabs/pdk/pull/945) ([david22swan](https://github.com/david22swan))
- Remove pre-condition checks for RSAPI objects [#943](https://github.com/puppetlabs/pdk/pull/943) ([DavidS](https://github.com/DavidS))
- Update lower puppet requirements bound when creating new modules [#942](https://github.com/puppetlabs/pdk/pull/942) ([DavidS](https://github.com/DavidS))
- Allow Facter4 to be co-installed with PDK [#941](https://github.com/puppetlabs/pdk/pull/941) ([GabrielNagy](https://github.com/GabrielNagy))
- Add ability to generate functions [#932](https://github.com/puppetlabs/pdk/pull/932) ([logicminds](https://github.com/logicminds))
- (GH-905) Ensure release failure includes error message [#929](https://github.com/puppetlabs/pdk/pull/929) ([michaeltlombardi](https://github.com/michaeltlombardi))
- Adds AIX support when creating a new module [#927](https://github.com/puppetlabs/pdk/pull/927) ([logicminds](https://github.com/logicminds))
- Add ability to generate new facts [#921](https://github.com/puppetlabs/pdk/pull/921) ([logicminds](https://github.com/logicminds))
- Add forge token env [#913](https://github.com/puppetlabs/pdk/pull/913) ([scotje](https://github.com/scotje))
- (FORGE-339) Omit .DS_Store files from module builds [#910](https://github.com/puppetlabs/pdk/pull/910) ([binford2k](https://github.com/binford2k))
- (#876) Refactor text report output when validators are skipped [#904](https://github.com/puppetlabs/pdk/pull/904) ([scotje](https://github.com/scotje))

### Other

- (#902) Check for `github_changelog_generator` in proper bundler context [#907](https://github.com/puppetlabs/pdk/pull/907) ([scotje](https://github.com/scotje))

## [v1.18.1](https://github.com/puppetlabs/pdk/tree/v1.18.1) - 2020-07-17

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.18.0...v1.18.1)

### Fixed

- Don't attempt to modify a frozen string when parsing '--tests' paths [#891](https://github.com/puppetlabs/pdk/pull/891) ([natemccurdy](https://github.com/natemccurdy))
- (PDK-1653) Ensure template have access to metadata during update/convert [#883](https://github.com/puppetlabs/pdk/pull/883) ([scotje](https://github.com/scotje))

## [v1.18.0](https://github.com/puppetlabs/pdk/tree/v1.18.0) - 2020-05-12

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.17.0...v1.18.0)

### Added

- (PDK-1109) Add pdk remove config [#870](https://github.com/puppetlabs/pdk/pull/870) ([glennsarti](https://github.com/glennsarti))
- (PDK-1632) Only show validators that are available in the given PDK Context [#867](https://github.com/puppetlabs/pdk/pull/867) ([glennsarti](https://github.com/glennsarti))
- (PDK-1615) Add validator for environment.conf [#866](https://github.com/puppetlabs/pdk/pull/866) ([glennsarti](https://github.com/glennsarti))
- (FIXUP) Make system config path absolute instead of relative on POSIX hosts [#862](https://github.com/puppetlabs/pdk/pull/862) ([scotje](https://github.com/scotje))
- (PDK-1108) Add pdk set config command [#859](https://github.com/puppetlabs/pdk/pull/859) ([glennsarti](https://github.com/glennsarti))

### Fixed

- Fix PDK release command module validation [#880](https://github.com/puppetlabs/pdk/pull/880) ([carabasdaniel](https://github.com/carabasdaniel))
- (GH-828) Munge backslash in rake paths for unit tests [#878](https://github.com/puppetlabs/pdk/pull/878) ([glennsarti](https://github.com/glennsarti))
- (GH-874) Use PDK Context root for PDK Convert and Update [#877](https://github.com/puppetlabs/pdk/pull/877) ([glennsarti](https://github.com/glennsarti))
- (#869) Ensure bundle update on convert/update [#871](https://github.com/puppetlabs/pdk/pull/871) ([rodjek](https://github.com/rodjek))
- (#821) Allow for unbalanced JSON fragments in RSpec output [#822](https://github.com/puppetlabs/pdk/pull/822) ([scotje](https://github.com/scotje))

## [v1.17.0](https://github.com/puppetlabs/pdk/tree/v1.17.0) - 2020-02-27

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.16.0...v1.17.0)

### Added

- (#855) Use correct namespace for external Bundler call [#860](https://github.com/puppetlabs/pdk/pull/860) ([rodjek](https://github.com/rodjek))
- (PDK-1618)(PDK-1613)(PDK-1616) Add Control Repo support to Validators [#858](https://github.com/puppetlabs/pdk/pull/858) ([glennsarti](https://github.com/glennsarti))
- (PDK-1614) Add project.environment settings [#857](https://github.com/puppetlabs/pdk/pull/857) ([glennsarti](https://github.com/glennsarti))
- (PDK-1615) Add Ini File configuration support [#856](https://github.com/puppetlabs/pdk/pull/856) ([glennsarti](https://github.com/glennsarti))
- (PDK-1612) Add PDK::Context and context detection [#853](https://github.com/puppetlabs/pdk/pull/853) ([glennsarti](https://github.com/glennsarti))
- (PDK-1607)(PDK-1608) Implement system-level settings for PDK configuration [#841](https://github.com/puppetlabs/pdk/pull/841) ([glennsarti](https://github.com/glennsarti))
- (PDK-1592) Refactor PDK validators to be more singular purpose [#831](https://github.com/puppetlabs/pdk/pull/831) ([glennsarti](https://github.com/glennsarti))

### Other

- (PDK-1522) Update package tests for OSX 10.15 [#852](https://github.com/puppetlabs/pdk/pull/852) ([rodjek](https://github.com/rodjek))
- (PDK-1113) Use PDK configuration instead of AnswerFile class [#842](https://github.com/puppetlabs/pdk/pull/842) ([glennsarti](https://github.com/glennsarti))

## [v1.16.0](https://github.com/puppetlabs/pdk/tree/v1.16.0) - 2020-02-05

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.15.0...v1.16.0)

### Added

- (PDK-1545) Include template-ref in module generation output [#840](https://github.com/puppetlabs/pdk/pull/840) ([rodjek](https://github.com/rodjek))
- (PDK-1590) Remove Gemfile.lock before running bundle update [#834](https://github.com/puppetlabs/pdk/pull/834) ([rodjek](https://github.com/rodjek))
- (PDK-1587) Reject paths with non-ASCII characters when building [#832](https://github.com/puppetlabs/pdk/pull/832) ([rodjek](https://github.com/rodjek))
- (PDK-1588) Increase granularity of `pdk bundle` analytics [#827](https://github.com/puppetlabs/pdk/pull/827) ([rodjek](https://github.com/rodjek))
- (PDK-1557) Detect Control Repositories [#826](https://github.com/puppetlabs/pdk/pull/826) ([glennsarti](https://github.com/glennsarti))
- (PDK-1556) Use the module root when generating objects [#824](https://github.com/puppetlabs/pdk/pull/824) ([glennsarti](https://github.com/glennsarti))

## [v1.15.0](https://github.com/puppetlabs/pdk/tree/v1.15.0) - 2019-12-13

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.14.1...v1.15.0)

### Added

- (PDK-1488) Inform user if updating a pinned module [#816](https://github.com/puppetlabs/pdk/pull/816) ([rodjek](https://github.com/rodjek))
- (PDK-1487) Add --default-template flag to pdk convert [#814](https://github.com/puppetlabs/pdk/pull/814) ([rodjek](https://github.com/rodjek))
- (GH-808) Implement pdk release prep and publish subcommands [#813](https://github.com/puppetlabs/pdk/pull/813) ([glennsarti](https://github.com/glennsarti))
- (GH-808) Implement pdk release subcommand [#809](https://github.com/puppetlabs/pdk/pull/809) ([glennsarti](https://github.com/glennsarti))
- (#806) Use ASCII quotes instead of Unicode quotes [#807](https://github.com/puppetlabs/pdk/pull/807) ([rodjek](https://github.com/rodjek))
- (PDK-1364) Allow non-git template directories to be used [#803](https://github.com/puppetlabs/pdk/pull/803) ([glennsarti](https://github.com/glennsarti))
- (PDK-1523) Refactor filesystem operations to use PDK::Util::Filesystem [#799](https://github.com/puppetlabs/pdk/pull/799) ([rodjek](https://github.com/rodjek))

### Fixed

- (GH-808) Fix prompt for pdk release [#812](https://github.com/puppetlabs/pdk/pull/812) ([glennsarti](https://github.com/glennsarti))
- (PDK-1169) Add VMWare fallback to PDK::Util::Filesystem.mv [#802](https://github.com/puppetlabs/pdk/pull/802) ([rodjek](https://github.com/rodjek))

### Other

- (PDK-1563) Prepare 1.15.0 release [#817](https://github.com/puppetlabs/pdk/pull/817) ([rodjek](https://github.com/rodjek))
- (PDK-1546) Bump beaker-hostgenerator for Fedora 31 support [#805](https://github.com/puppetlabs/pdk/pull/805) ([rodjek](https://github.com/rodjek))
- (MAINT) Fixup package tests for unexpected key in .sync.yml [#804](https://github.com/puppetlabs/pdk/pull/804) ([scotje](https://github.com/scotje))
- (PDK-1541) Bump version (back) to 1.15.0.pre [#797](https://github.com/puppetlabs/pdk/pull/797) ([scotje](https://github.com/scotje))
- (PDK-1442) Add basic interactive pdk bundle test [#736](https://github.com/puppetlabs/pdk/pull/736) ([rodjek](https://github.com/rodjek))

## [v1.14.1](https://github.com/puppetlabs/pdk/tree/v1.14.1) - 2019-11-01

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.14.0...v1.14.1)

### Added

- (maint) Raise error when template content is empty or nil [#794](https://github.com/puppetlabs/pdk/pull/794) ([rodjek](https://github.com/rodjek))
- (PDK-1530) Disable schema validation of config files [#793](https://github.com/puppetlabs/pdk/pull/793) ([glennsarti](https://github.com/glennsarti))
- (#764) Ensure --puppet-dev checkout is always updated [#792](https://github.com/puppetlabs/pdk/pull/792) ([rodjek](https://github.com/rodjek))
- (#773) Respect --verbose in interactive pdk test unit [#791](https://github.com/puppetlabs/pdk/pull/791) ([rodjek](https://github.com/rodjek))
- (PDK-1443) Windows safe Tempfiles & environment variable access [#790](https://github.com/puppetlabs/pdk/pull/790) ([rodjek](https://github.com/rodjek))
- (PDK-1519) Print deprecation notice on Ruby < 2.4 [#785](https://github.com/puppetlabs/pdk/pull/785) ([rodjek](https://github.com/rodjek))
- (GH-768) Fix in_module_root? gives false positives [#783](https://github.com/puppetlabs/pdk/pull/783) ([glennsarti](https://github.com/glennsarti))
- (#770) Add missing require to PDK::Module::Metadata.from_file [#771](https://github.com/puppetlabs/pdk/pull/771) ([hajee](https://github.com/hajee))

### Fixed

- (PDK-1527) Handle pdk new module --skip-interview without module name [#788](https://github.com/puppetlabs/pdk/pull/788) ([rodjek](https://github.com/rodjek))

### Other

- (PDK-1536) Prepare 1.14.1 release [#796](https://github.com/puppetlabs/pdk/pull/796) ([rodjek](https://github.com/rodjek))

## [v1.14.0](https://github.com/puppetlabs/pdk/tree/v1.14.0) - 2019-10-09

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.13.0...v1.14.0)

### Added

- (fixup) Fix Bundle CLI lazy load [#767](https://github.com/puppetlabs/pdk/pull/767) ([glennsarti](https://github.com/glennsarti))
- (fixup) Missing require from lazy load PR [#766](https://github.com/puppetlabs/pdk/pull/766) ([rodjek](https://github.com/rodjek))
- Add new "pdk console" command [#758](https://github.com/puppetlabs/pdk/pull/758) ([logicminds](https://github.com/logicminds))
- (PDK-1495) Update pdk new test UX [#749](https://github.com/puppetlabs/pdk/pull/749) ([rodjek](https://github.com/rodjek))
- (PDK-680) Make `pdk test unit` interactive by default [#748](https://github.com/puppetlabs/pdk/pull/748) ([rodjek](https://github.com/rodjek))
- (PDK-1367) Deprecation warning for Puppet < 5.0.0 [#747](https://github.com/puppetlabs/pdk/pull/747) ([rodjek](https://github.com/rodjek))
- (PDK-1047) Add --add-tests to pdk convert [#746](https://github.com/puppetlabs/pdk/pull/746) ([rodjek](https://github.com/rodjek))
- (PDK-1112) Create json schema to validate pdk config file [#742](https://github.com/puppetlabs/pdk/pull/742) ([glennsarti](https://github.com/glennsarti))

### Other

- (PDK-1511) Release 1.14.0 [#769](https://github.com/puppetlabs/pdk/pull/769) ([rodjek](https://github.com/rodjek))

## [v1.13.0](https://github.com/puppetlabs/pdk/tree/v1.13.0) - 2019-08-29

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.12.0...v1.13.0)

### Added

- (PDK-1175) pdk new unit_test [#735](https://github.com/puppetlabs/pdk/pull/735) ([rodjek](https://github.com/rodjek))
- (PDK-1384) Updates to be compatible with latest Cri [#731](https://github.com/puppetlabs/pdk/pull/731) ([scotje](https://github.com/scotje))
- (PDK-871) Relax dependencies on tty-* gems [#730](https://github.com/puppetlabs/pdk/pull/730) ([rodjek](https://github.com/rodjek))
- (PDK-1363) Apply init templates during module convert [#729](https://github.com/puppetlabs/pdk/pull/729) ([rodjek](https://github.com/rodjek))
- (PDK-1107) Config fetch and [] should have no side effects [#726](https://github.com/puppetlabs/pdk/pull/726) ([glennsarti](https://github.com/glennsarti))
- (PDK-1107) Add pdk config get CLI command [#715](https://github.com/puppetlabs/pdk/pull/715) ([glennsarti](https://github.com/glennsarti))
- (PDK-1432) Autogenerate PowerShell modules from code [#701](https://github.com/puppetlabs/pdk/pull/701) ([glennsarti](https://github.com/glennsarti))

### Fixed

- Handle deleted template files for new module [#725](https://github.com/puppetlabs/pdk/pull/725) ([seanmil](https://github.com/seanmil))
- (GH-722) Do not emit nil targets for validators against a directory [#724](https://github.com/puppetlabs/pdk/pull/724) ([glennsarti](https://github.com/glennsarti))

### Other

- (PDK-1474) Prepare 1.13.0 release [#739](https://github.com/puppetlabs/pdk/pull/739) ([rodjek](https://github.com/rodjek))

## [v1.12.0](https://github.com/puppetlabs/pdk/tree/v1.12.0) - 2019-07-31

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.11.1...v1.12.0)

### Added

- (FIXUP) Bypass shell invocation for PDK::CLI::Exec::InteractiveCommand [#717](https://github.com/puppetlabs/pdk/pull/717) ([scotje](https://github.com/scotje))
- (PDK-641) Make `pdk bundle` fully interactive [#712](https://github.com/puppetlabs/pdk/pull/712) ([scotje](https://github.com/scotje))
- (PDK-1366) Update default operatingsystem versions [#711](https://github.com/puppetlabs/pdk/pull/711) ([rodjek](https://github.com/rodjek))
- (PDK-421) Update acceptance tests for EPP Validation [#709](https://github.com/puppetlabs/pdk/pull/709) ([glennsarti](https://github.com/glennsarti))
- (PDK-1434) Gracefully handle unparsable bolt analytics config [#705](https://github.com/puppetlabs/pdk/pull/705) ([rodjek](https://github.com/rodjek))
- (FM-8081) pdk new transport [#696](https://github.com/puppetlabs/pdk/pull/696) ([DavidS](https://github.com/DavidS))
- (PDK-421) Validate EPP syntax [#680](https://github.com/puppetlabs/pdk/pull/680) ([raphink](https://github.com/raphink))
- (FM-8081) pdk new transport [#666](https://github.com/puppetlabs/pdk/pull/666) ([DavidS](https://github.com/DavidS))
- (PDK-1333) command_spec rake task [#644](https://github.com/puppetlabs/pdk/pull/644) ([rodjek](https://github.com/rodjek))

### Fixed

- (PDK-1309) Ensure file modes in built modules are sane [#713](https://github.com/puppetlabs/pdk/pull/713) ([rodjek](https://github.com/rodjek))
- (PDK-1333) Fix command_spec rake task for newer CRI versions [#699](https://github.com/puppetlabs/pdk/pull/699) ([glennsarti](https://github.com/glennsarti))

### Other

- (PDK-1449) Prepare 1.12.0 release [#718](https://github.com/puppetlabs/pdk/pull/718) ([rodjek](https://github.com/rodjek))

## [v1.11.1](https://github.com/puppetlabs/pdk/tree/v1.11.1) - 2019-07-01

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.11.0...v1.11.1)

### Added

- (PDK-1415) Allow analytics opt-out prompt to be disabled via ENV [#691](https://github.com/puppetlabs/pdk/pull/691) ([scotje](https://github.com/scotje))
- (PDK-1414) Detect common CI environments and set non-interactive [#689](https://github.com/puppetlabs/pdk/pull/689) ([glennsarti](https://github.com/glennsarti))

## [v1.11.0](https://github.com/puppetlabs/pdk/tree/v1.11.0) - 2019-06-27

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.10.0...v1.11.0)

### Added

- (PDK-1366) Update default operatingsystem versions [#682](https://github.com/puppetlabs/pdk/pull/682) ([rodjek](https://github.com/rodjek))
- (PDK-1362) Warn user if updating module with older PDK version [#681](https://github.com/puppetlabs/pdk/pull/681) ([rodjek](https://github.com/rodjek))
- (PDK-1365) Use dynamic ruby detection for default ruby instance [#678](https://github.com/puppetlabs/pdk/pull/678) ([glennsarti](https://github.com/glennsarti))
- (PDK-1354) Default template ref for custom templates should always be master [#677](https://github.com/puppetlabs/pdk/pull/677) ([rodjek](https://github.com/rodjek))
- (PDK-1337) Warn and unset any of the legacy *_GEM_VERSION env vars [#671](https://github.com/puppetlabs/pdk/pull/671) ([rodjek](https://github.com/rodjek))
- (PDK-1345) Disable analytics during package tests [#670](https://github.com/puppetlabs/pdk/pull/670) ([rodjek](https://github.com/rodjek))
- (PDK-1342) Submit PDK analytics events [#668](https://github.com/puppetlabs/pdk/pull/668) ([rodjek](https://github.com/rodjek))
- (PDK-1341) Hook up PDK analytics to Google Analytics [#665](https://github.com/puppetlabs/pdk/pull/665) ([rodjek](https://github.com/rodjek))
- (PDK-1264) Display a nicer error when tarring long paths [#663](https://github.com/puppetlabs/pdk/pull/663) ([rodjek](https://github.com/rodjek))
- (PDK-1339) Read or interview for analytics config [#657](https://github.com/puppetlabs/pdk/pull/657) ([rodjek](https://github.com/rodjek))
- (PDK-1350) Handle SCP style URLs in metadata.json [#655](https://github.com/puppetlabs/pdk/pull/655) ([rodjek](https://github.com/rodjek))
- (PDK-1338) Initial import of analytics code from Bolt [#652](https://github.com/puppetlabs/pdk/pull/652) ([rodjek](https://github.com/rodjek))
- (PDK-1193) Saves packaged template-url in metadata as a keyword [#639](https://github.com/puppetlabs/pdk/pull/639) ([bmjen](https://github.com/bmjen))

### Fixed

- (FIXUP) Avoid attempting to append nokogiri pin to nil in package tests [#686](https://github.com/puppetlabs/pdk/pull/686) ([scotje](https://github.com/scotje))
- (PDK-1300) Ensure `test unit --list` uses correct Puppet/Ruby env [#660](https://github.com/puppetlabs/pdk/pull/660) ([scotje](https://github.com/scotje))
- (PDK-1348) remove unused constants throwing warns [#656](https://github.com/puppetlabs/pdk/pull/656) ([tphoney](https://github.com/tphoney))
- (PDK-1335) Add development note when on Windows [#649](https://github.com/puppetlabs/pdk/pull/649) ([glennsarti](https://github.com/glennsarti))
- (PDK-1167) Validator should honor case sensitive of the file system [#646](https://github.com/puppetlabs/pdk/pull/646) ([glennsarti](https://github.com/glennsarti))

## [v1.10.0](https://github.com/puppetlabs/pdk/tree/v1.10.0) - 2019-04-02

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.9.1...v1.10.0)

### Added

- (PDK-1086) Change `pdk build --force` to warn if missing module metadata and continue [#643](https://github.com/puppetlabs/pdk/pull/643) ([rodjek](https://github.com/rodjek))
- (PDK-1308) Ensure PDK-written non-templated files have trailing newline [#640](https://github.com/puppetlabs/pdk/pull/640) ([scotje](https://github.com/scotje))
- (PDK-718) Add --template-ref argument for upstream template repo tags [#434](https://github.com/puppetlabs/pdk/pull/434) ([hunner](https://github.com/hunner))

## [v1.9.1](https://github.com/puppetlabs/pdk/tree/v1.9.1) - 2019-03-05

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.9.0...v1.9.1)

### Fixed

- (IMAGES-1037) Make sure our paths are used [#630](https://github.com/puppetlabs/pdk/pull/630) ([mihaibuzgau](https://github.com/mihaibuzgau))
- (PDK-1266) Clear modulepath value when validating manifest syntax [#629](https://github.com/puppetlabs/pdk/pull/629) ([rodjek](https://github.com/rodjek))
- (PDK-1272) Convert user/module module names to user-module [#626](https://github.com/puppetlabs/pdk/pull/626) ([rodjek](https://github.com/rodjek))
- (PDK-1276) Skip non-file YAML validator targets [#625](https://github.com/puppetlabs/pdk/pull/625) ([rodjek](https://github.com/rodjek))
- (PDK-1273) Allowlist Ruby symbols in YAML validator [#624](https://github.com/puppetlabs/pdk/pull/624) ([rodjek](https://github.com/rodjek))

## [v1.9.0](https://github.com/puppetlabs/pdk/tree/v1.9.0) - 2019-01-29

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.8.0...v1.9.0)

### Added

- (PDK-735) Implement a YAML validator [#612](https://github.com/puppetlabs/pdk/pull/612) ([rodjek](https://github.com/rodjek))

### Fixed

- (PDK-914) Adjust default_template_url validation to accept local dirs [#606](https://github.com/puppetlabs/pdk/pull/606) ([rodjek](https://github.com/rodjek))
- (PDK-1202) Pass TemplateDir object through to TemplateFile [#605](https://github.com/puppetlabs/pdk/pull/605) ([rodjek](https://github.com/rodjek))
- (PDK-1204) pdk bundle execs in the context of the pwd [#603](https://github.com/puppetlabs/pdk/pull/603) ([rodjek](https://github.com/rodjek))
- (PDK-1001) Chdir before execing git rather than "git -C" [#602](https://github.com/puppetlabs/pdk/pull/602) ([rodjek](https://github.com/rodjek))

## [v1.8.0](https://github.com/puppetlabs/pdk/tree/v1.8.0) - 2018-11-27

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.7.1...v1.8.0)

### Added

- (PDK-1090) Add task name validator for existing tasks [#598](https://github.com/puppetlabs/pdk/pull/598) ([rodjek](https://github.com/rodjek))
- (PDK-1208) Raise lower bound of 'puppet' requirement for new modules [#581](https://github.com/puppetlabs/pdk/pull/581) ([scotje](https://github.com/scotje))

### Fixed

- (PDK-1180) Cleanly handle a null pdk-version in metadata.json [#599](https://github.com/puppetlabs/pdk/pull/599) ([rodjek](https://github.com/rodjek))
- (PDK-1104) Don't always override custom template url with default [#597](https://github.com/puppetlabs/pdk/pull/597) ([rodjek](https://github.com/rodjek))
- (PDK-654) Allow rubocop to determine its own targets by default [#594](https://github.com/puppetlabs/pdk/pull/594) ([rodjek](https://github.com/rodjek))
- (PDK-1187) Don't override bundler path on gem installs [#592](https://github.com/puppetlabs/pdk/pull/592) ([rodjek](https://github.com/rodjek))
- (PDK-547) Ensure all PDK created files use LF line endings [#590](https://github.com/puppetlabs/pdk/pull/590) ([rodjek](https://github.com/rodjek))
- (PDK-1172) Call PDK::Util::Bundler.ensure_bundle! after module creation [#589](https://github.com/puppetlabs/pdk/pull/589) ([rodjek](https://github.com/rodjek))
- (PDK-1192) Add module_root/vendor/ to default ignored paths [#588](https://github.com/puppetlabs/pdk/pull/588) ([rodjek](https://github.com/rodjek))
- (PDK-1194) Exclude plans/**/*.pp from PDK::Validate::PuppetSyntax [#586](https://github.com/puppetlabs/pdk/pull/586) ([rodjek](https://github.com/rodjek))
- (PDK-972) Don't register a pending change when deleting non-existent files [#585](https://github.com/puppetlabs/pdk/pull/585) ([rodjek](https://github.com/rodjek))
- (PDK-1093) Replace null values and empty data structures in metadata when converting [#584](https://github.com/puppetlabs/pdk/pull/584) ([rodjek](https://github.com/rodjek))
- (PDK-400) Output the rspec run wall time in test unit summary [#583](https://github.com/puppetlabs/pdk/pull/583) ([rodjek](https://github.com/rodjek))
- (PDK-1200) Fix bundle env handling with puppet-dev [#579](https://github.com/puppetlabs/pdk/pull/579) ([bmjen](https://github.com/bmjen))
- (PDK-925) Exclude files that wouldn't be packaged from being validated [#578](https://github.com/puppetlabs/pdk/pull/578) ([rodjek](https://github.com/rodjek))

## [v1.7.1](https://github.com/puppetlabs/pdk/tree/v1.7.1) - 2018-10-08

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.7.0...v1.7.1)

### Added

- (PDK-1100) Exclude known artifacts from build instead of cleaning [#575](https://github.com/puppetlabs/pdk/pull/575) ([rodjek](https://github.com/rodjek))
- (PDK-1056) Adds support for Ruby 2.5.1 in packaged PDK version [#568](https://github.com/puppetlabs/pdk/pull/568) ([bmjen](https://github.com/bmjen))
- (PDK-1099) Merge Puppet::Util::Windows into PDK namespace [#565](https://github.com/puppetlabs/pdk/pull/565) ([rodjek](https://github.com/rodjek))

### Fixed

- (PDK-1181) Display error when metadata.json missing or unreadable [#574](https://github.com/puppetlabs/pdk/pull/574) ([rodjek](https://github.com/rodjek))
- (PDK-1173) Update pdk validate help output for powershell [#573](https://github.com/puppetlabs/pdk/pull/573) ([rodjek](https://github.com/rodjek))

## [v1.7.0](https://github.com/puppetlabs/pdk/tree/v1.7.0) - 2018-08-20

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.6.1...v1.7.0)

### Added

- (PDK-1096, PDK-1097, PDK-1098) Add puppet-dev flag to validate and test unit [#559](https://github.com/puppetlabs/pdk/pull/559) ([bmjen](https://github.com/bmjen))

### Fixed

- (PDK-585) Unify metadata defaults with/without interview [#558](https://github.com/puppetlabs/pdk/pull/558) ([rodjek](https://github.com/rodjek))

## [v1.6.1](https://github.com/puppetlabs/pdk/tree/v1.6.1) - 2018-07-25

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.6.0...v1.6.1)

### Added

- (PDK-1045) Send validation targets as relative file paths [#549](https://github.com/puppetlabs/pdk/pull/549) ([bmjen](https://github.com/bmjen))
- (PDK-1067) Ensure rspec-core binstubs are created for `pdk test unit` [#546](https://github.com/puppetlabs/pdk/pull/546) ([scotje](https://github.com/scotje))
- (PDK-1041) Improve handling of errors from PDK::Module::TemplateDir [#545](https://github.com/puppetlabs/pdk/pull/545) ([rodjek](https://github.com/rodjek))
- (PDK-1053) Print validator output on parse_output failure [#543](https://github.com/puppetlabs/pdk/pull/543) ([rodjek](https://github.com/rodjek))
- (PDK-1051) Expose rspec-puppet coverage results to PDK [#539](https://github.com/puppetlabs/pdk/pull/539) ([rodjek](https://github.com/rodjek))
- (PDK-1061) Ensure rake binstub when building module [#536](https://github.com/puppetlabs/pdk/pull/536) ([rodjek](https://github.com/rodjek))
- (PDK-925) Exclude files in spec/fixtures from globbed validation targets [#532](https://github.com/puppetlabs/pdk/pull/532) ([rodjek](https://github.com/rodjek))

### Fixed

- (PDK-1088) Remove unnecessary file enumeration loop during PDK build [#553](https://github.com/puppetlabs/pdk/pull/553) ([scotje](https://github.com/scotje))
- (PDK-1073) Fix gem bin paths for CLI::Exec managed subprocesses [#551](https://github.com/puppetlabs/pdk/pull/551) ([scotje](https://github.com/scotje))
- (PDK-1046) Improve handling of unexpected errors from puppet parser. [#541](https://github.com/puppetlabs/pdk/pull/541) ([bmjen](https://github.com/bmjen))
- Correct template path filter logic to only include regular files [#524](https://github.com/puppetlabs/pdk/pull/524) ([nabertrand](https://github.com/nabertrand))

## [v1.6.0](https://github.com/puppetlabs/pdk/tree/v1.6.0) - 2018-06-20

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.5.0...v1.6.0)

### Added

- (PDK-949) Add a default knockout_prefix for options [#517](https://github.com/puppetlabs/pdk/pull/517) ([jarretlavallee](https://github.com/jarretlavallee))
- (PDK-636) Make fixture cleaning optional [#515](https://github.com/puppetlabs/pdk/pull/515) ([rodjek](https://github.com/rodjek))
- (PDK-809) Exit early if the module is not PDK compatible [#506](https://github.com/puppetlabs/pdk/pull/506) ([rodjek](https://github.com/rodjek))

### Fixed

- (PDK-979) Set path to Gemfile when invoking `bundle lock` [#513](https://github.com/puppetlabs/pdk/pull/513) ([scotje](https://github.com/scotje))
- (PDK-985) Split validation targets into chunks of 1000 [#509](https://github.com/puppetlabs/pdk/pull/509) ([rodjek](https://github.com/rodjek))
- (PDK-926) Read rspec event context relative to module root [#508](https://github.com/puppetlabs/pdk/pull/508) ([rodjek](https://github.com/rodjek))
- Change Metadata.from_file to reliably raise [#503](https://github.com/puppetlabs/pdk/pull/503) ([DavidS](https://github.com/DavidS))
- (PDK-475) Set BUNDLE_IGNORE_CONFIG for all commands [#502](https://github.com/puppetlabs/pdk/pull/502) ([rodjek](https://github.com/rodjek))
- Ensure that the report.txt ends with a newline [#501](https://github.com/puppetlabs/pdk/pull/501) ([DavidS](https://github.com/DavidS))
- (MAINT) Fixup error in log output when parsing invalid .sync.yml [#498](https://github.com/puppetlabs/pdk/pull/498) ([scotje](https://github.com/scotje))
- Add yaml header to make yamllint happy [#496](https://github.com/puppetlabs/pdk/pull/496) ([wmuizelaar](https://github.com/wmuizelaar))
- (PDK-802) Work around OpenSSL multi-threading errors when needed [#494](https://github.com/puppetlabs/pdk/pull/494) ([scotje](https://github.com/scotje))

## [v1.5.0](https://github.com/puppetlabs/pdk/tree/v1.5.0) - 2018-04-30

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.4.1...v1.5.0)

### Added

- (PDK-904) Warns users of pdk version compatibility  [#482](https://github.com/puppetlabs/pdk/pull/482) ([bmjen](https://github.com/bmjen))
- (PDK-842) Wire puppet-version and pe-version options into subcommands [#480](https://github.com/puppetlabs/pdk/pull/480) ([scotje](https://github.com/scotje))
- (PDK-921) Update PDK::Util::Bundler helpers to support gem switching [#472](https://github.com/puppetlabs/pdk/pull/472) ([scotje](https://github.com/scotje))
- (maint) Allow `pdk bundle` to work without `--` [#466](https://github.com/puppetlabs/pdk/pull/466) ([DavidS](https://github.com/DavidS))
- (PDK-840) Add PDK::Util::PuppetVersion.from_module_metadata [#461](https://github.com/puppetlabs/pdk/pull/461) ([rodjek](https://github.com/rodjek))
- (PDK-877) Make PDK compatible with Ruby 2.5 [#459](https://github.com/puppetlabs/pdk/pull/459) ([scotje](https://github.com/scotje))
- Ruby 2.4.3 transition [#453](https://github.com/puppetlabs/pdk/pull/453) ([bmjen](https://github.com/bmjen))
- (PDK-846) add Resource API type unit test template [#451](https://github.com/puppetlabs/pdk/pull/451) ([tphoney](https://github.com/tphoney))
- (PDK-785) Add --puppet-version and --pe-version CLI options [#448](https://github.com/puppetlabs/pdk/pull/448) ([rodjek](https://github.com/rodjek))

### Fixed

- (FIXUP) Fix issue where PDK was invoking wrong Ruby on Windows [#492](https://github.com/puppetlabs/pdk/pull/492) ([scotje](https://github.com/scotje))
- (maint) Allow module name to contain underscores when verifying [#491](https://github.com/puppetlabs/pdk/pull/491) ([rodjek](https://github.com/rodjek))
- (MAINT) Make Bundler update_lock! helper more resilient [#489](https://github.com/puppetlabs/pdk/pull/489) ([scotje](https://github.com/scotje))
- (maint) Unhide parallel flag in test unit. [#486](https://github.com/puppetlabs/pdk/pull/486) ([bmjen](https://github.com/bmjen))
- (PDK-831, PDK-832) Fix ability to unmanage/delete files via .sync.yml  [#479](https://github.com/puppetlabs/pdk/pull/479) ([bmjen](https://github.com/bmjen))
- (FIXUP) Revert incorrect path change in PDK::CLI::Exec.bundle_bin [#478](https://github.com/puppetlabs/pdk/pull/478) ([scotje](https://github.com/scotje))
- (PDK-923) Honour PDK::Util::RubyVersion.active_ruby_version when executing commands [#474](https://github.com/puppetlabs/pdk/pull/474) ([rodjek](https://github.com/rodjek))
- (MAINT) Use `bundle lock --update` to pin json to built-in versions [#460](https://github.com/puppetlabs/pdk/pull/460) ([scotje](https://github.com/scotje))

## [v1.4.1](https://github.com/puppetlabs/pdk/tree/v1.4.1) - 2018-02-26

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.4.0...v1.4.1)

### Added

- Updates msg in pdk update on unconverted module [#442](https://github.com/puppetlabs/pdk/pull/442) ([bmjen](https://github.com/bmjen))

### Fixed

- pdk update and convert fixes [#433](https://github.com/puppetlabs/pdk/pull/433) ([bmjen](https://github.com/bmjen))

## [v1.4.0](https://github.com/puppetlabs/pdk/tree/v1.4.0) - 2018-02-21

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.3.2...v1.4.0)

### Added

- (PDK-754) Interview for missing or Forge only metadata before build [#422](https://github.com/puppetlabs/pdk/pull/422) ([bmjen](https://github.com/bmjen))
- (PDK-772) Refactor PDK::Module::Convert for re-use in PDK::Module::Update [#421](https://github.com/puppetlabs/pdk/pull/421) ([rodjek](https://github.com/rodjek))
- (PDK-771) Wireframe `pdk update` CLI [#419](https://github.com/puppetlabs/pdk/pull/419) ([rodjek](https://github.com/rodjek))
- (PDK-799) Adds validations and checks to pdk build workflow [#416](https://github.com/puppetlabs/pdk/pull/416) ([bmjen](https://github.com/bmjen))
- (PDK-758) Initial port & cleanup of the module build code [#411](https://github.com/puppetlabs/pdk/pull/411) ([rodjek](https://github.com/rodjek))
- (PDK-550) Removes unrequired questions from module interview [#410](https://github.com/puppetlabs/pdk/pull/410) ([bmjen](https://github.com/bmjen))
-  (PDK-506) pdk new provider [#409](https://github.com/puppetlabs/pdk/pull/409) ([DavidS](https://github.com/DavidS))
- (PDK-748) Wireframe `pdk build` CLI [#407](https://github.com/puppetlabs/pdk/pull/407) ([rodjek](https://github.com/rodjek))
- (PDK-575) Run puppet parser validate with an dummy empty puppet.conf [#402](https://github.com/puppetlabs/pdk/pull/402) ([rodjek](https://github.com/rodjek))

### Fixed

- (PDK-808) Fix to pdk update when there are sync.yml changes [#431](https://github.com/puppetlabs/pdk/pull/431) ([bmjen](https://github.com/bmjen))
- Update validation regex and error message for module name question [#430](https://github.com/puppetlabs/pdk/pull/430) ([ardrigh](https://github.com/ardrigh))
- (PDK-806) Update metadata interview text if metadata.json already exists [#429](https://github.com/puppetlabs/pdk/pull/429) ([rodjek](https://github.com/rodjek))
- (PDK-789) Add pdk metadata to all generated templatedirs. [#428](https://github.com/puppetlabs/pdk/pull/428) ([bmjen](https://github.com/bmjen))
- (FIXUP) Make `pdk build` overwrite prompt consistent [#427](https://github.com/puppetlabs/pdk/pull/427) ([scotje](https://github.com/scotje))
- (PDK-804) Fixes error in build without ignore file [#425](https://github.com/puppetlabs/pdk/pull/425) ([bmjen](https://github.com/bmjen))
- Small fixes [#415](https://github.com/puppetlabs/pdk/pull/415) ([DavidS](https://github.com/DavidS))

## [v1.3.2](https://github.com/puppetlabs/pdk/tree/v1.3.2) - 2018-01-17

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.3.1...v1.3.2)

### Added

- (PDK-552) Soften PDK::CLI::Util.ensure_in_module! error messages [#401](https://github.com/puppetlabs/pdk/pull/401) ([rodjek](https://github.com/rodjek))
- (PDK-739) Fall back to default template if necessary [#400](https://github.com/puppetlabs/pdk/pull/400) ([rodjek](https://github.com/rodjek))

## [v1.3.1](https://github.com/puppetlabs/pdk/tree/v1.3.1) - 2017-12-20

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.3.0...v1.3.1)

### Fixed

- (PDK-736) Improve handling of old template-url and template-ref [#397](https://github.com/puppetlabs/pdk/pull/397) ([scotje](https://github.com/scotje))

## [v1.3.0](https://github.com/puppetlabs/pdk/tree/v1.3.0) - 2017-12-15

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.2.1...v1.3.0)

### Added

- (PDK-489) unhide experimental commands [#384](https://github.com/puppetlabs/pdk/pull/384) ([DavidS](https://github.com/DavidS))
- (PDK-715) Transition pdk to use pdk-templates as template repo [#380](https://github.com/puppetlabs/pdk/pull/380) ([bmjen](https://github.com/bmjen))
- (PDK-728) Add default_template_ref handler. [#377](https://github.com/puppetlabs/pdk/pull/377) ([bmjen](https://github.com/bmjen))
- (PDK-725) Add timestamp to PDK Convert Report [#376](https://github.com/puppetlabs/pdk/pull/376) ([bmjen](https://github.com/bmjen))
- (PDK-724) Ensure dir exist before writing new files during updates. [#375](https://github.com/puppetlabs/pdk/pull/375) ([bmjen](https://github.com/bmjen))
- (PDK-713) Clean up old bundler env during convert [#373](https://github.com/puppetlabs/pdk/pull/373) ([rodjek](https://github.com/rodjek))
- (PDK-622) Unhide convert subcommand [#367](https://github.com/puppetlabs/pdk/pull/367) ([bmjen](https://github.com/bmjen))
- (maint) Add/update template metadata on convert [#366](https://github.com/puppetlabs/pdk/pull/366) ([rodjek](https://github.com/rodjek))
- (PDK-625) Formatting of modified status report and addition of full c… [#365](https://github.com/puppetlabs/pdk/pull/365) ([HelenCampbell](https://github.com/HelenCampbell))
- (PDK-672) List files changed from convert [#363](https://github.com/puppetlabs/pdk/pull/363) ([bmjen](https://github.com/bmjen))
- Additional user prompt [#361](https://github.com/puppetlabs/pdk/pull/361) ([rickmonro](https://github.com/rickmonro))
- Making exit errors generic for interview qs [#357](https://github.com/puppetlabs/pdk/pull/357) ([HelenCampbell](https://github.com/HelenCampbell))
- (PDK-624) Add UpdateManager class to handle making changes to module files [#355](https://github.com/puppetlabs/pdk/pull/355) ([rodjek](https://github.com/rodjek))
- (PDK-668) Templatedir now reads .sync.yml for config when rendering t… [#354](https://github.com/puppetlabs/pdk/pull/354) ([HelenCampbell](https://github.com/HelenCampbell))
- (PDK-643) Remove escape sequence spam when running in CI systems [#353](https://github.com/puppetlabs/pdk/pull/353) ([rodjek](https://github.com/rodjek))
- (PDK-627) Support for generating/updating metadata.json during convert [#352](https://github.com/puppetlabs/pdk/pull/352) ([rodjek](https://github.com/rodjek))
- (PDK-674) UX Improvement for listing unit test files. [#349](https://github.com/puppetlabs/pdk/pull/349) ([bmjen](https://github.com/bmjen))
- (PDK-673) Moving git commands into a util class [#347](https://github.com/puppetlabs/pdk/pull/347) ([HelenCampbell](https://github.com/HelenCampbell))
- (PDK-671) Makes module_name optional for pdk new module. [#344](https://github.com/puppetlabs/pdk/pull/344) ([bmjen](https://github.com/bmjen))
- (PDK-626) Templatedir can now handle multiple directories [#340](https://github.com/puppetlabs/pdk/pull/340) ([HelenCampbell](https://github.com/HelenCampbell))
- (PDK-621) Implement a skeleton `pdk convert` command [#335](https://github.com/puppetlabs/pdk/pull/335) ([rodjek](https://github.com/rodjek))
-  (PDK-628) Addition of module_name question to interview [#327](https://github.com/puppetlabs/pdk/pull/327) ([HelenCampbell](https://github.com/HelenCampbell))
- (PDK-594) mention the used template during `new module` [#321](https://github.com/puppetlabs/pdk/pull/321) ([DavidS](https://github.com/DavidS))

### Fixed

- (PDK-729) Remove Set usage in metadata [#393](https://github.com/puppetlabs/pdk/pull/393) ([rodjek](https://github.com/rodjek))
- Minor updates to convert dialog [#390](https://github.com/puppetlabs/pdk/pull/390) ([HelenCampbell](https://github.com/HelenCampbell))
- (PDK-643) Disable non-exec validator spinners when noninteractive [#385](https://github.com/puppetlabs/pdk/pull/385) ([rodjek](https://github.com/rodjek))
- (PDK 719) Directory layout and metadata fixes during convert [#383](https://github.com/puppetlabs/pdk/pull/383) ([HelenCampbell](https://github.com/HelenCampbell))
- (PDK-722) Remove prompt to continue from start of convert [#378](https://github.com/puppetlabs/pdk/pull/378) ([rodjek](https://github.com/rodjek))
- (PDK-723) Fixes bug where sync.yml wasn't being applied on convert [#374](https://github.com/puppetlabs/pdk/pull/374) ([bmjen](https://github.com/bmjen))
- (PDK-715) Use correct module template branch/ref [#368](https://github.com/puppetlabs/pdk/pull/368) ([bmjen](https://github.com/bmjen))
- Tweaks to dialog around module conversion [#362](https://github.com/puppetlabs/pdk/pull/362) ([HelenCampbell](https://github.com/HelenCampbell))
- (PDK-596) Accept "forgeuser-modulename" as argument to `new module`  [#358](https://github.com/puppetlabs/pdk/pull/358) ([DavidS](https://github.com/DavidS))
- (PDK-429) Fix --tests to pass through to unit test handler. [#351](https://github.com/puppetlabs/pdk/pull/351) ([bmjen](https://github.com/bmjen))

## [v1.2.1](https://github.com/puppetlabs/pdk/tree/v1.2.1) - 2017-10-26

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.2.0...v1.2.1)

### Fixed

- Add --relative cli argument for autoload layout testing in puppet-lint [#325](https://github.com/puppetlabs/pdk/pull/325) ([spacepants](https://github.com/spacepants))

## [v1.2.0](https://github.com/puppetlabs/pdk/tree/v1.2.0) - 2017-10-06

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.1.0...v1.2.0)

### Added

- (PDK-577) Add info line that task metadata was also generated [#312](https://github.com/puppetlabs/pdk/pull/312) ([DavidS](https://github.com/DavidS))
- Tasks Generation and Validation [#310](https://github.com/puppetlabs/pdk/pull/310) ([bmjen](https://github.com/bmjen))
- (PDK-479) new module: create examples/, and files/ directory [#308](https://github.com/puppetlabs/pdk/pull/308) ([DavidS](https://github.com/DavidS))
- (PDK-470) Validation of task metadata. [#301](https://github.com/puppetlabs/pdk/pull/301) ([bmjen](https://github.com/bmjen))
- (PDK-468) Adding parameters field to task metadata [#300](https://github.com/puppetlabs/pdk/pull/300) ([bmjen](https://github.com/bmjen))
- (PDK-468) `new task` command [#299](https://github.com/puppetlabs/pdk/pull/299) ([rodjek](https://github.com/rodjek))

### Fixed

- (PDK-408) Explain PowerShell escaping for -- on `bundle` [#309](https://github.com/puppetlabs/pdk/pull/309) ([DavidS](https://github.com/DavidS))
- (PDK-482) Update help messages to be less ambiguous [#307](https://github.com/puppetlabs/pdk/pull/307) ([DavidS](https://github.com/DavidS))
- (PDK-555) Handle windows style (backslash separated) paths when validating [#306](https://github.com/puppetlabs/pdk/pull/306) ([rodjek](https://github.com/rodjek))
- (PDK-543) Fix spdx.org URLs in messages [#303](https://github.com/puppetlabs/pdk/pull/303) ([farkasmate](https://github.com/farkasmate))
- (PDK-502) make the private git available to module commands [#298](https://github.com/puppetlabs/pdk/pull/298) ([rodjek](https://github.com/rodjek))

## [v1.1.0](https://github.com/puppetlabs/pdk/tree/v1.1.0) - 2017-09-13

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.0.1...v1.1.0)

### Added

- (PDK-369) Improve error context for pdk test unit failures [#294](https://github.com/puppetlabs/pdk/pull/294) ([rodjek](https://github.com/rodjek))
- (PDK-415) Convert user-input related problems from FATAL to ERROR [#293](https://github.com/puppetlabs/pdk/pull/293) ([rodjek](https://github.com/rodjek))
- (PDK-465) Improve output from spec_prep/spec_clean failures [#290](https://github.com/puppetlabs/pdk/pull/290) ([rodjek](https://github.com/rodjek))
- (PDK-465) Add vendored git to PATH for package installs [#287](https://github.com/puppetlabs/pdk/pull/287) ([rodjek](https://github.com/rodjek))
- (PDK-370) Adds a 'pdk module generate' redirect to 'pdk new module'. [#286](https://github.com/puppetlabs/pdk/pull/286) ([bmjen](https://github.com/bmjen))
- (PDK-459) Improve error message when the generation target exists [#285](https://github.com/puppetlabs/pdk/pull/285) ([DavidS](https://github.com/DavidS))
- (PDK-461) Update childprocess to current version [#282](https://github.com/puppetlabs/pdk/pull/282) ([DavidS](https://github.com/DavidS))
- (PDK-461) Make Version.git_ref more forgiving [#281](https://github.com/puppetlabs/pdk/pull/281) ([DavidS](https://github.com/DavidS))
- (PDK-459) Add defined type generator [#280](https://github.com/puppetlabs/pdk/pull/280) ([rodjek](https://github.com/rodjek))
- (MAINT) Copy-edited all the user-visible messages [#276](https://github.com/puppetlabs/pdk/pull/276) ([jbondpdx](https://github.com/jbondpdx))
- (PDK-365) Inform and prompt user following new module generate [#270](https://github.com/puppetlabs/pdk/pull/270) ([bmjen](https://github.com/bmjen))
- (maint) Debug output GEM_HOME and GEM_PATH before executing module commands [#268](https://github.com/puppetlabs/pdk/pull/268) ([james-stocks](https://github.com/james-stocks))
- (SDK-336) Add operating system question to the new module interview [#262](https://github.com/puppetlabs/pdk/pull/262) ([rodjek](https://github.com/rodjek))

### Fixed

- (PDK-450) remove stdlib dependency [#278](https://github.com/puppetlabs/pdk/pull/278) ([DavidS](https://github.com/DavidS))
- (PDK-420) Ensure Puppet and Puppet::Util modules are defined [#277](https://github.com/puppetlabs/pdk/pull/277) ([rodjek](https://github.com/rodjek))
- (PDK-430) Do not cache template-url answer if using the default template [#265](https://github.com/puppetlabs/pdk/pull/265) ([rodjek](https://github.com/rodjek))

## [v1.0.1](https://github.com/puppetlabs/pdk/tree/v1.0.1) - 2017-08-17

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.0.0...v1.0.1)

### Fixed

- (MAINT) Add package bin path to subprocess PATH [#261](https://github.com/puppetlabs/pdk/pull/261) ([austb](https://github.com/austb))
- (MAINT) Bump tty-prompt ver, remove monkey patch [#260](https://github.com/puppetlabs/pdk/pull/260) ([austb](https://github.com/austb))

## [v1.0.0](https://github.com/puppetlabs/pdk/tree/v1.0.0) - 2017-08-15

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.6.0...v1.0.0)

### Added

- (PDK-395) Use vendored pdk-module-template repo when available [#255](https://github.com/puppetlabs/pdk/pull/255) ([scotje](https://github.com/scotje))
- Move content from README to official docs site [#252](https://github.com/puppetlabs/pdk/pull/252) ([jbondpdx](https://github.com/jbondpdx))
- (PDK-367) Update questionnaire wording [#251](https://github.com/puppetlabs/pdk/pull/251) ([DavidS](https://github.com/DavidS))
- (PDK-406) Add GEM_HOME and GEM_PATH bin dirs to PATH when executing commands [#249](https://github.com/puppetlabs/pdk/pull/249) ([rodjek](https://github.com/rodjek))
- (PDK-401, PDK-402, PDK-403, PDK-404) Update validators to handle targets better [#248](https://github.com/puppetlabs/pdk/pull/248) ([bmjen](https://github.com/bmjen))
- (maint) Allow bundler to install gems in parallel [#245](https://github.com/puppetlabs/pdk/pull/245) ([james-stocks](https://github.com/james-stocks))
- (PDK-397) Log output of bundler commands at appropriate levels [#243](https://github.com/puppetlabs/pdk/pull/243) ([scotje](https://github.com/scotje))
- (PDK-396) Disable spinners in debug mode [#233](https://github.com/puppetlabs/pdk/pull/233) ([rodjek](https://github.com/rodjek))
- (PDK-388, PDK-392) Add README, CHANGELOG, and puppet requirement to module generation [#232](https://github.com/puppetlabs/pdk/pull/232) ([bmjen](https://github.com/bmjen))
- (SDK-144) Add option to run validate in parallel [#144](https://github.com/puppetlabs/pdk/pull/144) ([austb](https://github.com/austb))

### Fixed

- (PDK-407) Validate module interview confirmation answer [#237](https://github.com/puppetlabs/pdk/pull/237) ([rodjek](https://github.com/rodjek))
- (PDK-386) Remove parameter options from 'new class' [#236](https://github.com/puppetlabs/pdk/pull/236) ([austb](https://github.com/austb))

## [v0.6.0](https://github.com/puppetlabs/pdk/tree/v0.6.0) - 2017-08-08

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.5.0...v0.6.0)

### Added

- (MAINT) Improve moduleroot error message [#224](https://github.com/puppetlabs/pdk/pull/224) ([DavidS](https://github.com/DavidS))
- (MAINT) workaround rspec-puppt-facts being case-sensitive for operatingsystem filters [#222](https://github.com/puppetlabs/pdk/pull/222) ([DavidS](https://github.com/DavidS))
- (PDK-354) Change PDK::Logger to write to STDERR [#217](https://github.com/puppetlabs/pdk/pull/217) ([scotje](https://github.com/scotje))
- (SDK-331) Use vendored Gemfile.lock when available and needed [#215](https://github.com/puppetlabs/pdk/pull/215) ([scotje](https://github.com/scotje))
- (maint) Expose message when FileUtils.mkdir_p fails during module generation [#209](https://github.com/puppetlabs/pdk/pull/209) ([rodjek](https://github.com/rodjek))
- (SDK-323) Change color of default answer to cyan [#206](https://github.com/puppetlabs/pdk/pull/206) ([austb](https://github.com/austb))
- (maint) Remove unimplemented `add provider` from docs [#200](https://github.com/puppetlabs/pdk/pull/200) ([DavidS](https://github.com/DavidS))
- Update PowerShell install instructions [#194](https://github.com/puppetlabs/pdk/pull/194) ([jpogran](https://github.com/jpogran))
- (maint) Remove unused vcs option from 'pdk new module' [#192](https://github.com/puppetlabs/pdk/pull/192) ([rodjek](https://github.com/rodjek))
- Document compatibility policy and upgrade strategy [#188](https://github.com/puppetlabs/pdk/pull/188) ([turbodog](https://github.com/turbodog))
- (MAINT) Remove spinner for `bundle check` command [#187](https://github.com/puppetlabs/pdk/pull/187) ([scotje](https://github.com/scotje))
- (SDK-321) add `pdk validate help` [#183](https://github.com/puppetlabs/pdk/pull/183) ([DavidS](https://github.com/DavidS))
- (SDK-317) Ensure parent of 'pdk new module' is writable before generation [#175](https://github.com/puppetlabs/pdk/pull/175) ([rodjek](https://github.com/rodjek))
- (SDK-312) Add option --parallel to `pdk test unit` [#154](https://github.com/puppetlabs/pdk/pull/154) ([austb](https://github.com/austb))

### Fixed

- (SDK-325) Validate all should run all validators [#230](https://github.com/puppetlabs/pdk/pull/230) ([bmjen](https://github.com/bmjen))
- (PDK-373) Make test unit --list consistent with test unit [#216](https://github.com/puppetlabs/pdk/pull/216) ([james-stocks](https://github.com/james-stocks))
- (MAINT) Add --strict-dependencies to metadata-json-lint invocation [#213](https://github.com/puppetlabs/pdk/pull/213) ([scotje](https://github.com/scotje))
- (SDK-317) Replace File.writable? test with actually creating a test file [#207](https://github.com/puppetlabs/pdk/pull/207) ([scotje](https://github.com/scotje))
- (SDK-333) Rescue Interrupt cleanly [#199](https://github.com/puppetlabs/pdk/pull/199) ([scotje](https://github.com/scotje))
- (#137) Nicer response when binary doesn't exist [#149](https://github.com/puppetlabs/pdk/pull/149) ([rodjek](https://github.com/rodjek))

## [v0.5.0](https://github.com/puppetlabs/pdk/tree/v0.5.0) - 2017-07-20

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.4.4...v0.5.0)

### Added

- (SDK-329) implement running arbitrary commands in PDK's environment [#179](https://github.com/puppetlabs/pdk/pull/179) ([DavidS](https://github.com/DavidS))
- (maint) Add 2.1.9 as the minimum required ruby version in the gemspec [#176](https://github.com/puppetlabs/pdk/pull/176) ([rodjek](https://github.com/rodjek))

### Fixed

- (SDK-331) allow additional gems to be installed [#178](https://github.com/puppetlabs/pdk/pull/178) ([DavidS](https://github.com/DavidS))

## [v0.4.4](https://github.com/puppetlabs/pdk/tree/v0.4.4) - 2017-07-18

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.4.3...v0.4.4)

### Fixed

- (#158) (#166) Resolve issue loading bundler from gem installs [#170](https://github.com/puppetlabs/pdk/pull/170) ([scotje](https://github.com/scotje))
- (SDK-319) force usage of our ruby [#168](https://github.com/puppetlabs/pdk/pull/168) ([DavidS](https://github.com/DavidS))

## [v0.4.3](https://github.com/puppetlabs/pdk/tree/v0.4.3) - 2017-07-17

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.4.2...v0.4.3)

### Fixed

- (FIXUP) Fix default subprocess success/failure messages on Windows [#164](https://github.com/puppetlabs/pdk/pull/164) ([scotje](https://github.com/scotje))

## [v0.4.2](https://github.com/puppetlabs/pdk/tree/v0.4.2) - 2017-07-17

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.4.1...v0.4.2)

### Fixed

- (FIXUP) Add missing newlines in new module interview prompts [#161](https://github.com/puppetlabs/pdk/pull/161) ([scotje](https://github.com/scotje))
- Use default username when Etc.getlogin fails [#160](https://github.com/puppetlabs/pdk/pull/160) ([austb](https://github.com/austb))

## [v0.4.1](https://github.com/puppetlabs/pdk/tree/v0.4.1) - 2017-07-14

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.4.0...v0.4.1)

### Fixed

- (FIXUP) Resolve conflation of cachedir concepts [#153](https://github.com/puppetlabs/pdk/pull/153) ([scotje](https://github.com/scotje))

## [v0.4.0](https://github.com/puppetlabs/pdk/tree/v0.4.0) - 2017-07-14

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.3.0...v0.4.0)

### Added

- (SDK-306) Use vendored development gems in package install [#145](https://github.com/puppetlabs/pdk/pull/145) ([scotje](https://github.com/scotje))
- (SDK-299) Check metadata.json syntax before linting [#133](https://github.com/puppetlabs/pdk/pull/133) ([rodjek](https://github.com/rodjek))
- (SDK-305) Answer file to cache module interview answers, template-url etc [#132](https://github.com/puppetlabs/pdk/pull/132) ([rodjek](https://github.com/rodjek))
- (SDK-296) Allow target selection for the metadata validator [#124](https://github.com/puppetlabs/pdk/pull/124) ([rodjek](https://github.com/rodjek))

### Fixed

- (FIXUP) Fixes spec tests for answer_file [#150](https://github.com/puppetlabs/pdk/pull/150) ([bmjen](https://github.com/bmjen))
- (FIXUP) Change rubocop default json_data to a hash [#147](https://github.com/puppetlabs/pdk/pull/147) ([scotje](https://github.com/scotje))
- (FIXUP) Flatten parsed JSON output from puppet-lint before processing [#146](https://github.com/puppetlabs/pdk/pull/146) ([scotje](https://github.com/scotje))
- (maint) Remove nil values from metadata before generating JSON [#127](https://github.com/puppetlabs/pdk/pull/127) ([rodjek](https://github.com/rodjek))
- (SDK-298) Handle exception raised when an invalid report format is specified on the CLI [#125](https://github.com/puppetlabs/pdk/pull/125) ([rodjek](https://github.com/rodjek))

## [v0.3.0](https://github.com/puppetlabs/pdk/tree/v0.3.0) - 2017-06-29

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.2.0...v0.3.0)

### Added

- (MAINT) Add support for stacktrace to Report::Event class [#112](https://github.com/puppetlabs/pdk/pull/112) ([scotje](https://github.com/scotje))
- (MAINT) Various CLI::Exec improvements and updates [#111](https://github.com/puppetlabs/pdk/pull/111) ([scotje](https://github.com/scotje))
- (SDK-148) Add "test unit --list" [#107](https://github.com/puppetlabs/pdk/pull/107) ([james-stocks](https://github.com/james-stocks))
- (SDK-137) Add puppet syntax validation [#105](https://github.com/puppetlabs/pdk/pull/105) ([bmjen](https://github.com/bmjen))
- (SDK-285) Add --auto-correct flag to validators that support it [#104](https://github.com/puppetlabs/pdk/pull/104) ([rodjek](https://github.com/rodjek))
- (SDK-284) Add guidance for users during new module interview [#103](https://github.com/puppetlabs/pdk/pull/103) ([rodjek](https://github.com/rodjek))
- (SDK-147) Add 'test unit' runner and basic output formatting [#98](https://github.com/puppetlabs/pdk/pull/98) ([scotje](https://github.com/scotje))

### Fixed

- (SDK-297) Fixes writing reports to a file [#119](https://github.com/puppetlabs/pdk/pull/119) ([bmjen](https://github.com/bmjen))
- (SDK-290) Make sure that all usernames are processed when creating a new module [#108](https://github.com/puppetlabs/pdk/pull/108) ([austb](https://github.com/austb))
- (SDK-277) Exit cleanly if pdk commands are run outside of a module [#100](https://github.com/puppetlabs/pdk/pull/100) ([rodjek](https://github.com/rodjek))

## [v0.2.0](https://github.com/puppetlabs/pdk/tree/v0.2.0) - 2017-06-21

[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.1.0...v0.2.0)

### Added

- (SDK-137) Adds Puppet Parser syntax validation [#94](https://github.com/puppetlabs/pdk/pull/94) ([bmjen](https://github.com/bmjen))
- (SDK-274) Adds --version option [#90](https://github.com/puppetlabs/pdk/pull/90) ([bmjen](https://github.com/bmjen))
- Report format implementation [#81](https://github.com/puppetlabs/pdk/pull/81) ([rodjek](https://github.com/rodjek))
- (SDK-244) Add rubocop validation subcommand [#75](https://github.com/puppetlabs/pdk/pull/75) ([rodjek](https://github.com/rodjek))
- (maint) Add hints for gem installation [#74](https://github.com/puppetlabs/pdk/pull/74) ([DavidS](https://github.com/DavidS))
- (SDK-240) Adds puppet-lint validation subcommand [#71](https://github.com/puppetlabs/pdk/pull/71) ([bmjen](https://github.com/bmjen))
- (SDK-261) Manage basic bundler operations for module dev [#62](https://github.com/puppetlabs/pdk/pull/62) ([scotje](https://github.com/scotje))
- Relax data type validation to warn when non-standard types used [#59](https://github.com/puppetlabs/pdk/pull/59) ([rodjek](https://github.com/rodjek))
- (SDK-232) Add operatingsystem_support defaults [#58](https://github.com/puppetlabs/pdk/pull/58) ([DavidS](https://github.com/DavidS))

### Fixed

- (maint) avoid interfering with local ruby configs [#86](https://github.com/puppetlabs/pdk/pull/86) ([DavidS](https://github.com/DavidS))
- (FIXUP) Fixes module_root typo and validate nil handling [#72](https://github.com/puppetlabs/pdk/pull/72) ([bmjen](https://github.com/bmjen))
- (SDK-262) Populate default metadata to match interview defaults [#63](https://github.com/puppetlabs/pdk/pull/63) ([rodjek](https://github.com/rodjek))
- (maint) nokogiri: avoid versions without ruby 2.1 support [#60](https://github.com/puppetlabs/pdk/pull/60) ([DavidS](https://github.com/DavidS))

## [v0.1.0](https://github.com/puppetlabs/pdk/tree/v0.1.0) - 2017-06-05

[Full Changelog](https://github.com/puppetlabs/pdk/compare/2be9329bed4715c888f273814b99f2cf37ee9341...v0.1.0)
