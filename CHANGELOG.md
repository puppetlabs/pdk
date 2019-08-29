# Changelog

All changes to this repo will be documented in this file.
See the [release notes](https://puppet.com/docs/pdk/latest/release_notes.html) for a high-level summary.


## [v1.13.0](https://github.com/puppetlabs/pdk/tree/v1.13.0) (2019-08-29)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.12.0...v1.13.0)

**Implemented enhancements:**

- Don't buffer output from bundle commands [\#364](https://github.com/puppetlabs/pdk/issues/364)
- Provide official docker image with pdk [\#336](https://github.com/puppetlabs/pdk/issues/336)
- \(PDK-1175\) pdk new unit\_test [\#735](https://github.com/puppetlabs/pdk/pull/735) ([rodjek](https://github.com/rodjek))
- \(PDK-871\) Relax dependencies on tty-\* gems [\#730](https://github.com/puppetlabs/pdk/pull/730) ([rodjek](https://github.com/rodjek))
- \(PDK-1363\) Apply init templates during module convert [\#729](https://github.com/puppetlabs/pdk/pull/729) ([rodjek](https://github.com/rodjek))
- \(PDK-1107\) Add pdk config get CLI command [\#715](https://github.com/puppetlabs/pdk/pull/715) ([glennsarti](https://github.com/glennsarti))

**Fixed bugs:**

- Problem running "pdk validate manifests/" with pdk 1.12.0 [\#722](https://github.com/puppetlabs/pdk/issues/722)
- Windows MSI installer fails with PDK 1.12.0 [\#721](https://github.com/puppetlabs/pdk/issues/721)
- Handle deleted template files for new module [\#725](https://github.com/puppetlabs/pdk/pull/725) ([seanmil](https://github.com/seanmil))
- \(GH-722\) Do not emit nil targets for validators against a directory [\#724](https://github.com/puppetlabs/pdk/pull/724) ([glennsarti](https://github.com/glennsarti))
- \(maint\) avoid interfering with local ruby configs [\#86](https://github.com/puppetlabs/pdk/pull/86) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- \(FIXUP\) Remove nokogiri version pin from package-testing [\#738](https://github.com/puppetlabs/pdk/pull/738) ([scotje](https://github.com/scotje))
- \(PDK-1464\) Update nokogiri due to CVE-2019-5477 [\#733](https://github.com/puppetlabs/pdk/pull/733) ([glennsarti](https://github.com/glennsarti))
- \(PDK-1465\) Remove net-ssh from gemspec [\#732](https://github.com/puppetlabs/pdk/pull/732) ([glennsarti](https://github.com/glennsarti))
- \(PDK-1384\) Updates to be compatible with latest Cri [\#731](https://github.com/puppetlabs/pdk/pull/731) ([scotje](https://github.com/scotje))
- \(docs\) minor fixups to README [\#727](https://github.com/puppetlabs/pdk/pull/727) ([jbondpdx](https://github.com/jbondpdx))
- \(PDK-1107\) Config fetch and \[\] should have no side effects [\#726](https://github.com/puppetlabs/pdk/pull/726) ([glennsarti](https://github.com/glennsarti))
- \(MAINT\) Bump version to 1.13.0.pre [\#720](https://github.com/puppetlabs/pdk/pull/720) ([scotje](https://github.com/scotje))
- \(MAINT\) Allow use of RSPEC\_PATTERN env var when running package tests [\#719](https://github.com/puppetlabs/pdk/pull/719) ([scotje](https://github.com/scotje))
- \(maint\) Remove Hipchat notifications [\#716](https://github.com/puppetlabs/pdk/pull/716) ([glennsarti](https://github.com/glennsarti))
- \(PDK-1432\) Autogenerate PowerShell modules from code [\#701](https://github.com/puppetlabs/pdk/pull/701) ([glennsarti](https://github.com/glennsarti))

## [v1.12.0](https://github.com/puppetlabs/pdk/tree/v1.12.0) (2019-07-31)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.11.1...v1.12.0)

**Implemented enhancements:**

- \(PDK-421\) Validate EPP syntax [\#680](https://github.com/puppetlabs/pdk/pull/680) ([raphink](https://github.com/raphink))
- \(FM-8081\) pdk new transport [\#666](https://github.com/puppetlabs/pdk/pull/666) ([DavidS](https://github.com/DavidS))

**Fixed bugs:**

- Checking Ruby code style fails [\#697](https://github.com/puppetlabs/pdk/issues/697)
- template-url does not properly match ssh URI [\#653](https://github.com/puppetlabs/pdk/issues/653)
- pdk build should fix file + directory rights for tar file [\#618](https://github.com/puppetlabs/pdk/issues/618)

**Merged pull requests:**

- \(FIXUP\) Bypass shell invocation for PDK::CLI::Exec::InteractiveCommand [\#717](https://github.com/puppetlabs/pdk/pull/717) ([scotje](https://github.com/scotje))
- \(maint\) Expect pdk test unit to run more than 1 test [\#714](https://github.com/puppetlabs/pdk/pull/714) ([rodjek](https://github.com/rodjek))
- \(PDK-1309\) Ensure file modes in built modules are sane [\#713](https://github.com/puppetlabs/pdk/pull/713) ([rodjek](https://github.com/rodjek))
- \(PDK-641\) Make `pdk bundle` fully interactive [\#712](https://github.com/puppetlabs/pdk/pull/712) ([scotje](https://github.com/scotje))
- \(PDK-1366\) Update default operatingsystem versions [\#711](https://github.com/puppetlabs/pdk/pull/711) ([rodjek](https://github.com/rodjek))
- \(PDK-421\) Update acceptance tests for EPP Validation [\#709](https://github.com/puppetlabs/pdk/pull/709) ([glennsarti](https://github.com/glennsarti))
- \(PDK-1434\) Gracefully handle unparsable bolt analytics config [\#705](https://github.com/puppetlabs/pdk/pull/705) ([rodjek](https://github.com/rodjek))
- \(MAINT\) Add debug logging of yaml files being validated [\#704](https://github.com/puppetlabs/pdk/pull/704) ([npwalker](https://github.com/npwalker))
- \(maint\) Fix typo in gitignore [\#700](https://github.com/puppetlabs/pdk/pull/700) ([glennsarti](https://github.com/glennsarti))
- \(PDK-1333\) Fix command\_spec rake task for newer CRI versions [\#699](https://github.com/puppetlabs/pdk/pull/699) ([glennsarti](https://github.com/glennsarti))
- \(PDK-1429\) Bump version to 1.11.2.pre [\#698](https://github.com/puppetlabs/pdk/pull/698) ([scotje](https://github.com/scotje))
- \(FM-8081\) pdk new transport [\#696](https://github.com/puppetlabs/pdk/pull/696) ([DavidS](https://github.com/DavidS))
- \(maint\) Update beaker in package tests [\#695](https://github.com/puppetlabs/pdk/pull/695) ([rodjek](https://github.com/rodjek))
- Revert "Merge pull request \#666 from DavidS/fm-8081-pdk-new-transport" [\#693](https://github.com/puppetlabs/pdk/pull/693) ([DavidS](https://github.com/DavidS))
- \(maint\) Message and string fixes [\#676](https://github.com/puppetlabs/pdk/pull/676) ([DavidS](https://github.com/DavidS))
- \(PDK-1333\) command\_spec rake task [\#644](https://github.com/puppetlabs/pdk/pull/644) ([rodjek](https://github.com/rodjek))

## [v1.11.1](https://github.com/puppetlabs/pdk/tree/v1.11.1) (2019-07-01)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.11.0...v1.11.1)

**Closed issues:**

- PDK explicitly asking for consent to collect anonymous usage information [\#690](https://github.com/puppetlabs/pdk/issues/690)

**Merged pull requests:**

- \(PDK-1423\) Release 1.11.1 [\#692](https://github.com/puppetlabs/pdk/pull/692) ([rodjek](https://github.com/rodjek))
- \(PDK-1415\) Allow analytics opt-out prompt to be disabled via ENV [\#691](https://github.com/puppetlabs/pdk/pull/691) ([scotje](https://github.com/scotje))
- \(PDK-1414\) Detect common CI environments and set non-interactive [\#689](https://github.com/puppetlabs/pdk/pull/689) ([glennsarti](https://github.com/glennsarti))
- \(PDK-1409\) Bump PDK version to 1.11.1.pre [\#688](https://github.com/puppetlabs/pdk/pull/688) ([rodjek](https://github.com/rodjek))

## [v1.11.0](https://github.com/puppetlabs/pdk/tree/v1.11.0) (2019-06-27)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.10.0...v1.11.0)

**Fixed bugs:**

- \(PDK-1348\) remove unused constants throwing warns [\#656](https://github.com/puppetlabs/pdk/pull/656) ([tphoney](https://github.com/tphoney))

**Closed issues:**

- template-ref behaviour in PDK 1.10.0 breaks backwards compatibility [\#661](https://github.com/puppetlabs/pdk/issues/661)
- pdk validate reports error on is\_to\_s [\#642](https://github.com/puppetlabs/pdk/issues/642)
- pdk 1.9.1.0 on windows does not set path env variable [\#641](https://github.com/puppetlabs/pdk/issues/641)
- default\_facts.yml does not override values from facterdb [\#628](https://github.com/puppetlabs/pdk/issues/628)
- PDK and beaker [\#622](https://github.com/puppetlabs/pdk/issues/622)
- Configure 'ordering' for rspec-puppet in PDK [\#511](https://github.com/puppetlabs/pdk/issues/511)
- Cannot override module Hiera 5 config for unit tests [\#487](https://github.com/puppetlabs/pdk/issues/487)

**Merged pull requests:**

- \(PDK-1403\) Release 1.11.0 [\#687](https://github.com/puppetlabs/pdk/pull/687) ([rodjek](https://github.com/rodjek))
- \(FIXUP\) Avoid attempting to append nokogiri pin to nil in package tests [\#686](https://github.com/puppetlabs/pdk/pull/686) ([scotje](https://github.com/scotje))
- Revert "\(PDK-1366\) Update default operatingsystem versions" [\#685](https://github.com/puppetlabs/pdk/pull/685) ([rodjek](https://github.com/rodjek))
- \(maint\) Clear Gemfile overrides before pdk update test [\#684](https://github.com/puppetlabs/pdk/pull/684) ([rodjek](https://github.com/rodjek))
- \(PDK-1366\) Update default operatingsystem versions [\#682](https://github.com/puppetlabs/pdk/pull/682) ([rodjek](https://github.com/rodjek))
- \(PDK-1362\) Warn user if updating module with older PDK version [\#681](https://github.com/puppetlabs/pdk/pull/681) ([rodjek](https://github.com/rodjek))
- \(PDK-1365\) Use dynamic ruby detection for default ruby instance [\#678](https://github.com/puppetlabs/pdk/pull/678) ([glennsarti](https://github.com/glennsarti))
- \(PDK-1354\) Default template ref for custom templates should always be master [\#677](https://github.com/puppetlabs/pdk/pull/677) ([rodjek](https://github.com/rodjek))
- \(maint\) Pin cri to \<= 2.15.6 [\#675](https://github.com/puppetlabs/pdk/pull/675) ([rodjek](https://github.com/rodjek))
- \(MAINT\) Fix issues related to Cri behavior change with options hash [\#672](https://github.com/puppetlabs/pdk/pull/672) ([scotje](https://github.com/scotje))
- \(PDK-1337\) Warn and unset any of the legacy \*\_GEM\_VERSION env vars [\#671](https://github.com/puppetlabs/pdk/pull/671) ([rodjek](https://github.com/rodjek))
- \(PDK-1345\) Disable analytics during package tests [\#670](https://github.com/puppetlabs/pdk/pull/670) ([rodjek](https://github.com/rodjek))
- \(MAINT\) Fix MSYS2 update on Appveyor [\#669](https://github.com/puppetlabs/pdk/pull/669) ([rodjek](https://github.com/rodjek))
- \(PDK-1342\) Submit PDK analytics events [\#668](https://github.com/puppetlabs/pdk/pull/668) ([rodjek](https://github.com/rodjek))
- \(PDK-1336\) Update rubocop to 0.57.2 [\#667](https://github.com/puppetlabs/pdk/pull/667) ([scotje](https://github.com/scotje))
- \(PDK-1341\) Hook up PDK analytics to Google Analytics [\#665](https://github.com/puppetlabs/pdk/pull/665) ([rodjek](https://github.com/rodjek))
- \(MAINT\) Add "needs-triage" default labels to issue templates [\#664](https://github.com/puppetlabs/pdk/pull/664) ([scotje](https://github.com/scotje))
- \(PDK-1264\) Display a nicer error when tarring long paths [\#663](https://github.com/puppetlabs/pdk/pull/663) ([rodjek](https://github.com/rodjek))
- \(maint\) Add spawned process stdout & stderr to debug log [\#662](https://github.com/puppetlabs/pdk/pull/662) ([rodjek](https://github.com/rodjek))
- \(PDK-1300\) Ensure `test unit --list` uses correct Puppet/Ruby env [\#660](https://github.com/puppetlabs/pdk/pull/660) ([scotje](https://github.com/scotje))
- \(MAINT\) Fixup package acceptance tests for 'pdk-default' template URL [\#658](https://github.com/puppetlabs/pdk/pull/658) ([scotje](https://github.com/scotje))
- \(PDK-1339\) Read or interview for analytics config [\#657](https://github.com/puppetlabs/pdk/pull/657) ([rodjek](https://github.com/rodjek))
- \(PDK-1350\) Handle SCP style URLs in metadata.json [\#655](https://github.com/puppetlabs/pdk/pull/655) ([rodjek](https://github.com/rodjek))
- \(PDK-1338\) Initial import of analytics code from Bolt [\#652](https://github.com/puppetlabs/pdk/pull/652) ([rodjek](https://github.com/rodjek))
- \(MAINT\) Bump version to 1.11.0.pre [\#651](https://github.com/puppetlabs/pdk/pull/651) ([scotje](https://github.com/scotje))
- \(PDK-1335\) Add development note when on Windows [\#649](https://github.com/puppetlabs/pdk/pull/649) ([glennsarti](https://github.com/glennsarti))
- \(maint\) Allow developers to add additional gems [\#648](https://github.com/puppetlabs/pdk/pull/648) ([glennsarti](https://github.com/glennsarti))
- \(PDK-1167\) Validator should honor case sensitive of the file system [\#646](https://github.com/puppetlabs/pdk/pull/646) ([glennsarti](https://github.com/glennsarti))
- \(PDK-1193\) Saves packaged template-url in metadata as a keyword [\#639](https://github.com/puppetlabs/pdk/pull/639) ([bmjen](https://github.com/bmjen))

## [v1.10.0](https://github.com/puppetlabs/pdk/tree/v1.10.0) (2019-04-02)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.9.1...v1.10.0)

**Implemented enhancements:**

- \(PDK-1086\) Change `pdk build --force` to warn if missing module metadata and continue [\#643](https://github.com/puppetlabs/pdk/pull/643) ([rodjek](https://github.com/rodjek))
- \(PDK-1308\) Ensure PDK-written non-templated files have trailing newline [\#640](https://github.com/puppetlabs/pdk/pull/640) ([scotje](https://github.com/scotje))
- \(PDK-718\) Add --template-ref argument for upstream template repo tags [\#434](https://github.com/puppetlabs/pdk/pull/434) ([hunner](https://github.com/hunner))

**Closed issues:**

- `pdk update` is not idempotent for deletion of CI config files [\#593](https://github.com/puppetlabs/pdk/issues/593)
- Rspec tests for CRLF line endings fail [\#587](https://github.com/puppetlabs/pdk/issues/587)
- class params feature in class object template not documented or useable [\#557](https://github.com/puppetlabs/pdk/issues/557)
- Disabling puppet-lint checks in PDK [\#538](https://github.com/puppetlabs/pdk/issues/538)

**Merged pull requests:**

- \(PDK-1324\) Release 1.10.0 [\#650](https://github.com/puppetlabs/pdk/pull/650) ([rodjek](https://github.com/rodjek))
- \(maint\) Fix package specs for template-ref changes [\#647](https://github.com/puppetlabs/pdk/pull/647) ([rodjek](https://github.com/rodjek))
- \(maint\) Enforce LF line endings in Rubocop [\#645](https://github.com/puppetlabs/pdk/pull/645) ([glennsarti](https://github.com/glennsarti))
- \(FM-7579, PDK-1236\) bump the version of CRI used [\#638](https://github.com/puppetlabs/pdk/pull/638) ([tphoney](https://github.com/tphoney))
- \(PDK-1294\) Update version post-release [\#637](https://github.com/puppetlabs/pdk/pull/637) ([bmjen](https://github.com/bmjen))
- \(PDK-1298\) acceptance:local test suite optimisation [\#633](https://github.com/puppetlabs/pdk/pull/633) ([rodjek](https://github.com/rodjek))

## [v1.9.1](https://github.com/puppetlabs/pdk/tree/v1.9.1) (2019-03-01)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.9.0...v1.9.1)

**Fixed bugs:**

- \(IMAGES-1037\) Make sure our paths are used [\#630](https://github.com/puppetlabs/pdk/pull/630) ([mihaibuzgau](https://github.com/mihaibuzgau))
- \(PDK-1266\) Clear modulepath value when validating manifest syntax [\#629](https://github.com/puppetlabs/pdk/pull/629) ([rodjek](https://github.com/rodjek))
- \(PDK-1272\) Convert user/module module names to user-module [\#626](https://github.com/puppetlabs/pdk/pull/626) ([rodjek](https://github.com/rodjek))
- \(PDK-1276\) Skip non-file YAML validator targets [\#625](https://github.com/puppetlabs/pdk/pull/625) ([rodjek](https://github.com/rodjek))
- \(PDK-1273\) Whitelist Ruby symbols in YAML validator [\#624](https://github.com/puppetlabs/pdk/pull/624) ([rodjek](https://github.com/rodjek))

**Merged pull requests:**

- \(PDK-1289\) Release 1.9.1 [\#632](https://github.com/puppetlabs/pdk/pull/632) ([bmjen](https://github.com/bmjen))
- \(maint\) Pin parallel gem to 1.13.0 [\#631](https://github.com/puppetlabs/pdk/pull/631) ([rodjek](https://github.com/rodjek))
- \(PDK-1260\) Bump to 1.10.0.pre for new dev work [\#621](https://github.com/puppetlabs/pdk/pull/621) ([bmjen](https://github.com/bmjen))

## [v1.9.0](https://github.com/puppetlabs/pdk/tree/v1.9.0) (2019-01-29)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.8.0...v1.9.0)

**Implemented enhancements:**

- \(PDK-735\) Implement a YAML validator [\#612](https://github.com/puppetlabs/pdk/pull/612) ([rodjek](https://github.com/rodjek))

**Fixed bugs:**

- \(PDK-914\) Adjust default\_template\_url validation to accept local dirs [\#606](https://github.com/puppetlabs/pdk/pull/606) ([rodjek](https://github.com/rodjek))
- \(PDK-1204\) pdk bundle execs in the context of the pwd [\#603](https://github.com/puppetlabs/pdk/pull/603) ([rodjek](https://github.com/rodjek))

**Closed issues:**

- After today upgrade rubygems-update the check for ruby 2.1.9 is completely broken [\#609](https://github.com/puppetlabs/pdk/issues/609)
- 'unknown type yumrepo' during 'pdk test unit' [\#607](https://github.com/puppetlabs/pdk/issues/607)

**Merged pull requests:**

- \(maint\) Fix pin for nokogiri in package tests [\#620](https://github.com/puppetlabs/pdk/pull/620) ([bmjen](https://github.com/bmjen))
- \(PDK-1240\) Update nokogiri to minimum of 1.8.5 [\#619](https://github.com/puppetlabs/pdk/pull/619) ([bmjen](https://github.com/bmjen))
- \(maint\) Update hitimes pin to 1.3.0 for r2.1 compat [\#617](https://github.com/puppetlabs/pdk/pull/617) ([bmjen](https://github.com/bmjen))
- Release 1.9.0 [\#616](https://github.com/puppetlabs/pdk/pull/616) ([bmjen](https://github.com/bmjen))
- \(MAINT\) Configure Slack notifications for Travis [\#614](https://github.com/puppetlabs/pdk/pull/614) ([scotje](https://github.com/scotje))
- \(maint\) Fix package tests to remove hardcoding [\#613](https://github.com/puppetlabs/pdk/pull/613) ([bmjen](https://github.com/bmjen))
- \(MAINT\) Fix package acceptance tests to pass with any Ruby 2.4.x [\#611](https://github.com/puppetlabs/pdk/pull/611) ([scotje](https://github.com/scotje))
- \(MAINT\) Bump default packaged ruby version to 2.4.5 [\#608](https://github.com/puppetlabs/pdk/pull/608) ([scotje](https://github.com/scotje))
- \(PDK-1202\) Pass TemplateDir object through to TemplateFile [\#605](https://github.com/puppetlabs/pdk/pull/605) ([rodjek](https://github.com/rodjek))
- \(PDK-1231\) Update version for new dev cycle. [\#604](https://github.com/puppetlabs/pdk/pull/604) ([bmjen](https://github.com/bmjen))
- \(PDK-1001\) Chdir before execing git rather than "git -C" [\#602](https://github.com/puppetlabs/pdk/pull/602) ([rodjek](https://github.com/rodjek))

## [v1.8.0](https://github.com/puppetlabs/pdk/tree/v1.8.0) (2018-11-28)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.7.1...v1.8.0)

**Implemented enhancements:**

- \(PDK-1090\) Add task name validator for existing tasks [\#598](https://github.com/puppetlabs/pdk/pull/598) ([rodjek](https://github.com/rodjek))

**Fixed bugs:**

- \(PDK-1180\) Cleanly handle a null pdk-version in metadata.json [\#599](https://github.com/puppetlabs/pdk/pull/599) ([rodjek](https://github.com/rodjek))
- \(PDK-1104\) Don't always override custom template url with default [\#597](https://github.com/puppetlabs/pdk/pull/597) ([rodjek](https://github.com/rodjek))
- \(PDK-654\) Allow rubocop to determine its own targets by default [\#594](https://github.com/puppetlabs/pdk/pull/594) ([rodjek](https://github.com/rodjek))
- \(PDK-1187\) Don't override bundler path on gem installs [\#592](https://github.com/puppetlabs/pdk/pull/592) ([rodjek](https://github.com/rodjek))
- \(PDK-547\) Ensure all PDK created files use LF line endings [\#590](https://github.com/puppetlabs/pdk/pull/590) ([rodjek](https://github.com/rodjek))
- \(PDK-1172\) Call PDK::Util::Bundler.ensure\_bundle! after module creation [\#589](https://github.com/puppetlabs/pdk/pull/589) ([rodjek](https://github.com/rodjek))
- \(PDK-1192\) Add module\_root/vendor/ to default ignored paths [\#588](https://github.com/puppetlabs/pdk/pull/588) ([rodjek](https://github.com/rodjek))
- \(PDK-1194\) Exclude plans/\*\*/\*.pp from PDK::Validate::PuppetSyntax [\#586](https://github.com/puppetlabs/pdk/pull/586) ([rodjek](https://github.com/rodjek))
- \(PDK-972\) Don't register a pending change when deleting non-existent files [\#585](https://github.com/puppetlabs/pdk/pull/585) ([rodjek](https://github.com/rodjek))
- \(PDK-1093\) Replace null values and empty data structures in metadata when converting [\#584](https://github.com/puppetlabs/pdk/pull/584) ([rodjek](https://github.com/rodjek))
- \(PDK-400\) Output the rspec run wall time in test unit summary [\#583](https://github.com/puppetlabs/pdk/pull/583) ([rodjek](https://github.com/rodjek))
- \(PDK-1200\) Fix bundle env handling with puppet-dev [\#579](https://github.com/puppetlabs/pdk/pull/579) ([bmjen](https://github.com/bmjen))
- \(PDK-925\) Exclude files that wouldn't be packaged from being validated [\#578](https://github.com/puppetlabs/pdk/pull/578) ([rodjek](https://github.com/rodjek))

**Closed issues:**

- Pdk validate should not assume that all puppet: URL require 'modules/'. [\#591](https://github.com/puppetlabs/pdk/issues/591)
- Create configuration to Overide default parameters [\#542](https://github.com/puppetlabs/pdk/issues/542)

**Merged pull requests:**

- Release 1.8.0 [\#601](https://github.com/puppetlabs/pdk/pull/601) ([bmjen](https://github.com/bmjen))
- \(maint\) Update package tests to add task name validation [\#600](https://github.com/puppetlabs/pdk/pull/600) ([bmjen](https://github.com/bmjen))
- \(maint\) Fix package tests [\#596](https://github.com/puppetlabs/pdk/pull/596) ([rodjek](https://github.com/rodjek))
- \(maint\) Add --skip-bundle-install to `pdk new module` [\#595](https://github.com/puppetlabs/pdk/pull/595) ([rodjek](https://github.com/rodjek))
- \(PDK-1208\) Raise lower bound of 'puppet' requirement for new modules [\#581](https://github.com/puppetlabs/pdk/pull/581) ([scotje](https://github.com/scotje))
- \(maint\) Bump version for dev [\#577](https://github.com/puppetlabs/pdk/pull/577) ([bmjen](https://github.com/bmjen))

## [v1.7.1](https://github.com/puppetlabs/pdk/tree/v1.7.1) (2018-10-05)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.7.0...v1.7.1)

**Implemented enhancements:**

- \(PDK-1100\) Exclude known artifacts from build instead of cleaning [\#575](https://github.com/puppetlabs/pdk/pull/575) ([rodjek](https://github.com/rodjek))
- \(PDK-1056\) Adds support for Ruby 2.5.1 in packaged PDK version [\#568](https://github.com/puppetlabs/pdk/pull/568) ([bmjen](https://github.com/bmjen))
- \(PDK-1099\) Merge Puppet::Util::Windows into PDK namespace [\#565](https://github.com/puppetlabs/pdk/pull/565) ([rodjek](https://github.com/rodjek))

**Fixed bugs:**

- \(PDK-1181\) Display error when metadata.json missing or unreadable [\#574](https://github.com/puppetlabs/pdk/pull/574) ([rodjek](https://github.com/rodjek))
- \(PDK-1173\) Update pdk validate help output for powershell [\#573](https://github.com/puppetlabs/pdk/pull/573) ([rodjek](https://github.com/rodjek))

**Merged pull requests:**

- Release Prep for 1.7.1 [\#576](https://github.com/puppetlabs/pdk/pull/576) ([bmjen](https://github.com/bmjen))
- \(maint\) Update PDK metadata defaults to include Puppet 6 [\#572](https://github.com/puppetlabs/pdk/pull/572) ([bmjen](https://github.com/bmjen))
- \(maint\) Update package tests for ruby 2.5.1 as the new default [\#571](https://github.com/puppetlabs/pdk/pull/571) ([bmjen](https://github.com/bmjen))
- Bump version to 1.8.0.pre [\#564](https://github.com/puppetlabs/pdk/pull/564) ([bmjen](https://github.com/bmjen))

## [v1.7.0](https://github.com/puppetlabs/pdk/tree/v1.7.0) (2018-08-15)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.6.1...v1.7.0)

**Implemented enhancements:**

- \(PDK-1096, PDK-1097, PDK-1098\) Add puppet-dev flag to validate and test unit [\#559](https://github.com/puppetlabs/pdk/pull/559) ([bmjen](https://github.com/bmjen))

**Fixed bugs:**

- \(PDK-585\) Unify metadata defaults with/without interview [\#558](https://github.com/puppetlabs/pdk/pull/558) ([rodjek](https://github.com/rodjek))

**Merged pull requests:**

- Release 1.7.0 [\#563](https://github.com/puppetlabs/pdk/pull/563) ([bmjen](https://github.com/bmjen))
- \(maint\) Fix package tests [\#562](https://github.com/puppetlabs/pdk/pull/562) ([bmjen](https://github.com/bmjen))
- \(PDK-1083\) Bump PDK version to 1.7.0.pre [\#556](https://github.com/puppetlabs/pdk/pull/556) ([rodjek](https://github.com/rodjek))
- \(PDK-1077\) Expand the package acceptance test suite [\#554](https://github.com/puppetlabs/pdk/pull/554) ([rodjek](https://github.com/rodjek))

## [v1.6.1](https://github.com/puppetlabs/pdk/tree/v1.6.1) (2018-07-25)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.6.0...v1.6.1)

**Implemented enhancements:**

- PDK `test unit` should cache downloaded modules [\#339](https://github.com/puppetlabs/pdk/issues/339)

**Fixed bugs:**

- acceptance tests message bundler: command not found: rspec [\#535](https://github.com/puppetlabs/pdk/issues/535)
- PDK 1.6.0: parallel\_spec causes Puppet coverage reports to change badly [\#531](https://github.com/puppetlabs/pdk/issues/531)
- Support for deep directory structure in templates [\#445](https://github.com/puppetlabs/pdk/issues/445)
- \(PDK-1046\) Improve handling of unexpected errors from puppet parser. [\#541](https://github.com/puppetlabs/pdk/pull/541) ([bmjen](https://github.com/bmjen))
- Correct template path filter logic to only include regular files [\#524](https://github.com/puppetlabs/pdk/pull/524) ([nabertrand](https://github.com/nabertrand))

**Closed issues:**

- r10k puppetfile install return r10k/cli \(LoadError\) [\#534](https://github.com/puppetlabs/pdk/issues/534)
- PDK 1.6.0: c.hiera\_config double quotes creates rubocop warning [\#530](https://github.com/puppetlabs/pdk/issues/530)
- PDK should support integration testing [\#481](https://github.com/puppetlabs/pdk/issues/481)

**Merged pull requests:**

- \(PDK-1078\) Prepare 1.6.1 release [\#555](https://github.com/puppetlabs/pdk/pull/555) ([rodjek](https://github.com/rodjek))
- \(PDK-1088\) Remove unnecessary file enumeration loop during PDK build [\#553](https://github.com/puppetlabs/pdk/pull/553) ([scotje](https://github.com/scotje))
- \(PDK-1076\) Change version to 1.6.1.pre [\#552](https://github.com/puppetlabs/pdk/pull/552) ([rodjek](https://github.com/rodjek))
- \(PDK-1073\) Fix gem bin paths for CLI::Exec managed subprocesses [\#551](https://github.com/puppetlabs/pdk/pull/551) ([scotje](https://github.com/scotje))
- Set up issues templates for bug reports and feature requests [\#550](https://github.com/puppetlabs/pdk/pull/550) ([scotje](https://github.com/scotje))
- \(PDK-1045\) Send validation targets as relative file paths [\#549](https://github.com/puppetlabs/pdk/pull/549) ([bmjen](https://github.com/bmjen))
- \(PDK-1067\) Ensure rspec-core binstubs are created for `pdk test unit` [\#546](https://github.com/puppetlabs/pdk/pull/546) ([scotje](https://github.com/scotje))
- \(PDK-1041\) Improve handling of errors from PDK::Module::TemplateDir [\#545](https://github.com/puppetlabs/pdk/pull/545) ([rodjek](https://github.com/rodjek))
- \(PDK-1053\) Print validator output on parse\_output failure [\#543](https://github.com/puppetlabs/pdk/pull/543) ([rodjek](https://github.com/rodjek))
- \(PDK-1051\) Expose rspec-puppet coverage results to PDK [\#539](https://github.com/puppetlabs/pdk/pull/539) ([rodjek](https://github.com/rodjek))
- \(PDK-1048\) Improve docs for `pdk test unit --verbose` [\#537](https://github.com/puppetlabs/pdk/pull/537) ([rodjek](https://github.com/rodjek))
- \(PDK-1061\) Ensure rake binstub when building module [\#536](https://github.com/puppetlabs/pdk/pull/536) ([rodjek](https://github.com/rodjek))
- \(PDK-925\) Exclude files in spec/fixtures from globbed validation targets [\#532](https://github.com/puppetlabs/pdk/pull/532) ([rodjek](https://github.com/rodjek))
- \(maint\) Bump version for next dev cycle [\#529](https://github.com/puppetlabs/pdk/pull/529) ([bmjen](https://github.com/bmjen))

## [v1.6.0](https://github.com/puppetlabs/pdk/tree/v1.6.0) (2018-06-21)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.5.0...v1.6.0)

**Implemented enhancements:**

- \(PDK-949\) Add a default knockout\_prefix for options [\#517](https://github.com/puppetlabs/pdk/pull/517) ([jarretlavallee](https://github.com/jarretlavallee))
- \(PDK-636\) Make fixture cleaning optional [\#515](https://github.com/puppetlabs/pdk/pull/515) ([rodjek](https://github.com/rodjek))
- \(PDK-809\) Exit early if the module is not PDK compatible [\#506](https://github.com/puppetlabs/pdk/pull/506) ([rodjek](https://github.com/rodjek))

**Fixed bugs:**

- pdk \(FATAL\): Could not locate Gemfile [\#505](https://github.com/puppetlabs/pdk/issues/505)
- pdk convert ignoring .sync.yml `delete` values [\#444](https://github.com/puppetlabs/pdk/issues/444)
- \(PDK-979\) Set path to Gemfile when invoking `bundle lock` [\#513](https://github.com/puppetlabs/pdk/pull/513) ([scotje](https://github.com/scotje))
- \(PDK-985\) Split validation targets into chunks of 1000 [\#509](https://github.com/puppetlabs/pdk/pull/509) ([rodjek](https://github.com/rodjek))
- \(PDK-926\) Read rspec event context relative to module root [\#508](https://github.com/puppetlabs/pdk/pull/508) ([rodjek](https://github.com/rodjek))
- Change Metadata.from\_file to reliably raise [\#503](https://github.com/puppetlabs/pdk/pull/503) ([DavidS](https://github.com/DavidS))
- \(PDK-475\) Set BUNDLE\_IGNORE\_CONFIG for all commands [\#502](https://github.com/puppetlabs/pdk/pull/502) ([rodjek](https://github.com/rodjek))
- \(MAINT\) Fixup error in log output when parsing invalid .sync.yml [\#498](https://github.com/puppetlabs/pdk/pull/498) ([scotje](https://github.com/scotje))
- Add yaml header to make yamllint happy [\#496](https://github.com/puppetlabs/pdk/pull/496) ([wmuizelaar](https://github.com/wmuizelaar))
- \(PDK-802\) Work around OpenSSL multi-threading errors when needed [\#494](https://github.com/puppetlabs/pdk/pull/494) ([scotje](https://github.com/scotje))

**Closed issues:**

- Creating packages from this repo [\#519](https://github.com/puppetlabs/pdk/issues/519)
- PDK fails to checkout template from git repo on CentOS 7 [\#490](https://github.com/puppetlabs/pdk/issues/490)

**Merged pull requests:**

- \(maint\) Handle tagged template-refs [\#527](https://github.com/puppetlabs/pdk/pull/527) ([rodjek](https://github.com/rodjek))
- Release 1.6.0 [\#526](https://github.com/puppetlabs/pdk/pull/526) ([bmjen](https://github.com/bmjen))
- \(maint\) Switch package-testing to install from build\_data\_url. [\#522](https://github.com/puppetlabs/pdk/pull/522) ([bmjen](https://github.com/bmjen))
- CI cleanups [\#507](https://github.com/puppetlabs/pdk/pull/507) ([DavidS](https://github.com/DavidS))
- Ensure that the report.txt ends with a newline [\#501](https://github.com/puppetlabs/pdk/pull/501) ([DavidS](https://github.com/DavidS))
- \(MAINT\) Bump beaker and beaker-hostgenerator for new platforms [\#499](https://github.com/puppetlabs/pdk/pull/499) ([scotje](https://github.com/scotje))
- \(maint\) Bumps version for 1.6.0 dev cycle. [\#497](https://github.com/puppetlabs/pdk/pull/497) ([bmjen](https://github.com/bmjen))
- Convert package acceptance tests over to beaker-rspec & serverspec [\#495](https://github.com/puppetlabs/pdk/pull/495) ([rodjek](https://github.com/rodjek))

## [v1.5.0](https://github.com/puppetlabs/pdk/tree/v1.5.0) (2018-04-30)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.4.1...v1.5.0)

**Implemented enhancements:**

- \(PDK-904\) Warns users of pdk version compatibility  [\#482](https://github.com/puppetlabs/pdk/pull/482) ([bmjen](https://github.com/bmjen))
- \(maint\) Allow `pdk bundle` to work without `--` [\#466](https://github.com/puppetlabs/pdk/pull/466) ([DavidS](https://github.com/DavidS))
- \(PDK-877\) Make PDK compatible with Ruby 2.5 [\#459](https://github.com/puppetlabs/pdk/pull/459) ([scotje](https://github.com/scotje))
- Ruby 2.4.3 transition [\#453](https://github.com/puppetlabs/pdk/pull/453) ([bmjen](https://github.com/bmjen))
- \(PDK-846\) add Resource API type unit test template [\#451](https://github.com/puppetlabs/pdk/pull/451) ([tphoney](https://github.com/tphoney))
- \(PDK-785\) Add --puppet-version and --pe-version CLI options [\#448](https://github.com/puppetlabs/pdk/pull/448) ([rodjek](https://github.com/rodjek))

**Fixed bugs:**

- \(PDK-877\) `make\_tmpdir\_name': undefined method `make\_tmpname' for Dir::Tmpname:Module [\#455](https://github.com/puppetlabs/pdk/issues/455)
- pdk validate fails if host puppet.conf contains deprecated settings [\#304](https://github.com/puppetlabs/pdk/issues/304)
- \(maint\) Allow module name to contain underscores when verifying [\#491](https://github.com/puppetlabs/pdk/pull/491) ([rodjek](https://github.com/rodjek))
- \(MAINT\) Make Bundler update\_lock! helper more resilient [\#489](https://github.com/puppetlabs/pdk/pull/489) ([scotje](https://github.com/scotje))
- \(maint\) Unhide parallel flag in test unit. [\#486](https://github.com/puppetlabs/pdk/pull/486) ([bmjen](https://github.com/bmjen))
- \(PDK-831, PDK-832\) Fix ability to unmanage/delete files via .sync.yml  [\#479](https://github.com/puppetlabs/pdk/pull/479) ([bmjen](https://github.com/bmjen))
- \(MAINT\) Use `bundle lock --update` to pin json to built-in versions [\#460](https://github.com/puppetlabs/pdk/pull/460) ([scotje](https://github.com/scotje))

**Closed issues:**

- PDK should default to mock\_with :rspec and resolve deprecation message [\#477](https://github.com/puppetlabs/pdk/issues/477)
- Support for template URL with a branch [\#447](https://github.com/puppetlabs/pdk/issues/447)
- Any interest in adding a `--parallel` option to `pdk test unit`? [\#446](https://github.com/puppetlabs/pdk/issues/446)
- Installing PDK from .deb causes unmet dependencies on Ubuntu 17.10 Artful [\#370](https://github.com/puppetlabs/pdk/issues/370)
- Repo Configs Contain Invalid URLs [\#319](https://github.com/puppetlabs/pdk/issues/319)
- Gems not found in pre-release [\#254](https://github.com/puppetlabs/pdk/issues/254)
- Running PDK behind a corporate proxy fails [\#227](https://github.com/puppetlabs/pdk/issues/227)

**Merged pull requests:**

- Release 1.5.0 [\#493](https://github.com/puppetlabs/pdk/pull/493) ([bmjen](https://github.com/bmjen))
- \(FIXUP\) Fix issue where PDK was invoking wrong Ruby on Windows [\#492](https://github.com/puppetlabs/pdk/pull/492) ([scotje](https://github.com/scotje))
- \(maint\) Update package testing for ruby 2.4.4. [\#488](https://github.com/puppetlabs/pdk/pull/488) ([bmjen](https://github.com/bmjen))
- \(MAINT\) Fix package tests for version selection and airgapped usage [\#485](https://github.com/puppetlabs/pdk/pull/485) ([scotje](https://github.com/scotje))
- \(maint\) Some minor corrections to CLI strings. [\#484](https://github.com/puppetlabs/pdk/pull/484) ([bmjen](https://github.com/bmjen))
- \(maint\) Remove static PE version map from PDK::Util::PuppetVersion [\#483](https://github.com/puppetlabs/pdk/pull/483) ([rodjek](https://github.com/rodjek))
- \(PDK-842\) Wire puppet-version and pe-version options into subcommands [\#480](https://github.com/puppetlabs/pdk/pull/480) ([scotje](https://github.com/scotje))
- \(FIXUP\) Revert incorrect path change in PDK::CLI::Exec.bundle\_bin [\#478](https://github.com/puppetlabs/pdk/pull/478) ([scotje](https://github.com/scotje))
- \(maint\) Allow users to major or major.minor versions [\#475](https://github.com/puppetlabs/pdk/pull/475) ([rodjek](https://github.com/rodjek))
- \(PDK-923\) Honour PDK::Util::RubyVersion.active\_ruby\_version when executing commands [\#474](https://github.com/puppetlabs/pdk/pull/474) ([rodjek](https://github.com/rodjek))
- \(MAINT\) Fix argument bug with BundleHelper\#update\_lock! [\#473](https://github.com/puppetlabs/pdk/pull/473) ([scotje](https://github.com/scotje))
- \(PDK-921\) Update PDK::Util::Bundler helpers to support gem switching [\#472](https://github.com/puppetlabs/pdk/pull/472) ([scotje](https://github.com/scotje))
- Link to PDK template repo [\#470](https://github.com/puppetlabs/pdk/pull/470) ([turbodog](https://github.com/turbodog))
- \(maint\) Update bundler before build because Ruby 2.5 [\#465](https://github.com/puppetlabs/pdk/pull/465) ([DavidS](https://github.com/DavidS))
- \(MAINT\) Refactor templatedir path\_or\_url calculation [\#462](https://github.com/puppetlabs/pdk/pull/462) ([scotje](https://github.com/scotje))
- \(PDK-840\) Add PDK::Util::PuppetVersion.from\_module\_metadata [\#461](https://github.com/puppetlabs/pdk/pull/461) ([rodjek](https://github.com/rodjek))
- \(maint\) bump dev version [\#458](https://github.com/puppetlabs/pdk/pull/458) ([bmjen](https://github.com/bmjen))
- \(MAINT\) Add Ruby 2.5 to Travis and Appveyor config [\#457](https://github.com/puppetlabs/pdk/pull/457) ([scotje](https://github.com/scotje))
- \(maint\) Fixup remaining ruby 2.4.3 issues [\#454](https://github.com/puppetlabs/pdk/pull/454) ([bmjen](https://github.com/bmjen))

## [v1.4.1](https://github.com/puppetlabs/pdk/tree/v1.4.1) (2018-02-26)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.4.0...v1.4.1)

**Fixed bugs:**

- pdk update and convert fixes [\#433](https://github.com/puppetlabs/pdk/pull/433) ([bmjen](https://github.com/bmjen))

**Merged pull requests:**

- Release 1.4.1 amend [\#443](https://github.com/puppetlabs/pdk/pull/443) ([bmjen](https://github.com/bmjen))
- Updates msg in pdk update on unconverted module [\#442](https://github.com/puppetlabs/pdk/pull/442) ([bmjen](https://github.com/bmjen))
- Release 1.4.1 amend [\#441](https://github.com/puppetlabs/pdk/pull/441) ([bmjen](https://github.com/bmjen))
- \(maint\) pdk update checks if module is pdk compat [\#440](https://github.com/puppetlabs/pdk/pull/440) ([bmjen](https://github.com/bmjen))
- Release 1.4.1 amend [\#439](https://github.com/puppetlabs/pdk/pull/439) ([bmjen](https://github.com/bmjen))
- \(maint\) add a `pdk module build` command to point to `pdk build` [\#438](https://github.com/puppetlabs/pdk/pull/438) ([DavidS](https://github.com/DavidS))
- \(maint\) unhide the `update` command [\#437](https://github.com/puppetlabs/pdk/pull/437) ([DavidS](https://github.com/DavidS))
- \(maint\) update: don't mention deleted Gemfile.lock and .bundle/config [\#436](https://github.com/puppetlabs/pdk/pull/436) ([DavidS](https://github.com/DavidS))
- Release 1.4.1 [\#435](https://github.com/puppetlabs/pdk/pull/435) ([bmjen](https://github.com/bmjen))

## [v1.4.0](https://github.com/puppetlabs/pdk/tree/v1.4.0) (2018-02-21)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.3.2...v1.4.0)

**Implemented enhancements:**

- \(PDK-771\) Wireframe `pdk update` CLI [\#419](https://github.com/puppetlabs/pdk/pull/419) ([rodjek](https://github.com/rodjek))
- \(PDK-550\) Removes unrequired questions from module interview [\#410](https://github.com/puppetlabs/pdk/pull/410) ([bmjen](https://github.com/bmjen))
-  \(PDK-506\) pdk new provider [\#409](https://github.com/puppetlabs/pdk/pull/409) ([DavidS](https://github.com/DavidS))
- \(PDK-748\) Wireframe `pdk build` CLI [\#407](https://github.com/puppetlabs/pdk/pull/407) ([rodjek](https://github.com/rodjek))

**Fixed bugs:**

- if a newer rubocop version is installed, pdk should fall-back to safe defaults [\#420](https://github.com/puppetlabs/pdk/issues/420)
- Update validation regex and error message for module name question [\#430](https://github.com/puppetlabs/pdk/pull/430) ([ardrigh](https://github.com/ardrigh))
- \(PDK-789\) Add pdk metadata to all generated templatedirs. [\#428](https://github.com/puppetlabs/pdk/pull/428) ([bmjen](https://github.com/bmjen))

**Closed issues:**

- WS1.Reputation - Symantec Endpoint Protection [\#403](https://github.com/puppetlabs/pdk/issues/403)
- task input\_method 'powershell' fails validation [\#369](https://github.com/puppetlabs/pdk/issues/369)
- PDK should have an option to disable progress indicator to make it usable in CI [\#323](https://github.com/puppetlabs/pdk/issues/323)

**Merged pull requests:**

- Release 1.4.0 [\#432](https://github.com/puppetlabs/pdk/pull/432) ([bmjen](https://github.com/bmjen))
- \(PDK-808\) Fix to pdk update when there are sync.yml changes [\#431](https://github.com/puppetlabs/pdk/pull/431) ([bmjen](https://github.com/bmjen))
- \(PDK-806\) Update metadata interview text if metadata.json already exists [\#429](https://github.com/puppetlabs/pdk/pull/429) ([rodjek](https://github.com/rodjek))
- \(FIXUP\) Make `pdk build` overwrite prompt consistent [\#427](https://github.com/puppetlabs/pdk/pull/427) ([scotje](https://github.com/scotje))
- \(maint\) Update unit tests to use exit\_zero/exit\_nonzero matchers [\#426](https://github.com/puppetlabs/pdk/pull/426) ([rodjek](https://github.com/rodjek))
- \(PDK-804\) Fixes error in build without ignore file [\#425](https://github.com/puppetlabs/pdk/pull/425) ([bmjen](https://github.com/bmjen))
- \(PDK-799\) Adds unit tests for the UX validation [\#423](https://github.com/puppetlabs/pdk/pull/423) ([bmjen](https://github.com/bmjen))
- \(PDK-754\) Interview for missing or Forge only metadata before build [\#422](https://github.com/puppetlabs/pdk/pull/422) ([bmjen](https://github.com/bmjen))
- \(PDK-772\) Refactor PDK::Module::Convert for re-use in PDK::Module::Update [\#421](https://github.com/puppetlabs/pdk/pull/421) ([rodjek](https://github.com/rodjek))
- Revert "\(maint\) pin pdk-templates version ref to workaround puppet 5.… [\#418](https://github.com/puppetlabs/pdk/pull/418) ([bmjen](https://github.com/bmjen))
- \(PDK-799\) Adds validations and checks to pdk build workflow [\#416](https://github.com/puppetlabs/pdk/pull/416) ([bmjen](https://github.com/bmjen))
- Small fixes [\#415](https://github.com/puppetlabs/pdk/pull/415) ([DavidS](https://github.com/DavidS))
- \(maint\) Make sure we use pdk-templates master if in development [\#414](https://github.com/puppetlabs/pdk/pull/414) ([bmjen](https://github.com/bmjen))
- \(maint\) bump version for dev. [\#412](https://github.com/puppetlabs/pdk/pull/412) ([bmjen](https://github.com/bmjen))
- \(PDK-758\) Initial port & cleanup of the module build code [\#411](https://github.com/puppetlabs/pdk/pull/411) ([rodjek](https://github.com/rodjek))
- \(maint\) Fix error templatedir error message [\#408](https://github.com/puppetlabs/pdk/pull/408) ([DavidS](https://github.com/DavidS))
- \(MAINT\) remove dead code [\#406](https://github.com/puppetlabs/pdk/pull/406) ([DavidS](https://github.com/DavidS))
- \(PDK-575\) Run puppet parser validate with an dummy empty puppet.conf [\#402](https://github.com/puppetlabs/pdk/pull/402) ([rodjek](https://github.com/rodjek))

## [v1.3.2](https://github.com/puppetlabs/pdk/tree/v1.3.2) (2018-01-17)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.3.1...v1.3.2)

**Closed issues:**

- "pdk convert" and "pdk new module" fails on OSX Sierra [\#396](https://github.com/puppetlabs/pdk/issues/396)
- Update shipped ruby [\#395](https://github.com/puppetlabs/pdk/issues/395)
- Puppet and PDK T-Shirts [\#381](https://github.com/puppetlabs/pdk/issues/381)

**Merged pull requests:**

- \(maint\) Default PDK::TEMPLATE\_REF to PDK::VERSION [\#405](https://github.com/puppetlabs/pdk/pull/405) ([rodjek](https://github.com/rodjek))
- 1.3.2 Release Prep [\#404](https://github.com/puppetlabs/pdk/pull/404) ([HelenCampbell](https://github.com/HelenCampbell))
- \(PDK-552\) Soften PDK::CLI::Util.ensure\_in\_module! error messages [\#401](https://github.com/puppetlabs/pdk/pull/401) ([rodjek](https://github.com/rodjek))
- \(PDK-739\) Fall back to default template if necessary [\#400](https://github.com/puppetlabs/pdk/pull/400) ([rodjek](https://github.com/rodjek))

## [v1.3.1](https://github.com/puppetlabs/pdk/tree/v1.3.1) (2017-12-20)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.3.0...v1.3.1)

**Fixed bugs:**

- \(PDK-736\) Improve handling of old template-url and template-ref [\#397](https://github.com/puppetlabs/pdk/pull/397) ([scotje](https://github.com/scotje))

**Merged pull requests:**

- Release Prep for 1.3.1 Hotfix [\#398](https://github.com/puppetlabs/pdk/pull/398) ([HelenCampbell](https://github.com/HelenCampbell))

## [v1.3.0](https://github.com/puppetlabs/pdk/tree/v1.3.0) (2017-12-15)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.2.1...v1.3.0)

**Implemented enhancements:**

- \(PDK-715\) Transition pdk to use pdk-templates as template repo [\#380](https://github.com/puppetlabs/pdk/pull/380) ([bmjen](https://github.com/bmjen))
- \(PDK-622\) Unhide convert subcommand [\#367](https://github.com/puppetlabs/pdk/pull/367) ([bmjen](https://github.com/bmjen))
- \(maint\) Add/update template metadata on convert [\#366](https://github.com/puppetlabs/pdk/pull/366) ([rodjek](https://github.com/rodjek))
- \(PDK-625\) Formatting of modified status report and addition of full c… [\#365](https://github.com/puppetlabs/pdk/pull/365) ([HelenCampbell](https://github.com/HelenCampbell))
- \(PDK-672\) List files changed from convert [\#363](https://github.com/puppetlabs/pdk/pull/363) ([bmjen](https://github.com/bmjen))
- \(PDK-668\) Templatedir now reads .sync.yml for config when rendering t… [\#354](https://github.com/puppetlabs/pdk/pull/354) ([HelenCampbell](https://github.com/HelenCampbell))
- \(PDK-643\) Remove escape sequence spam when running in CI systems [\#353](https://github.com/puppetlabs/pdk/pull/353) ([rodjek](https://github.com/rodjek))
- \(PDK-671\) Makes module\_name optional for pdk new module. [\#344](https://github.com/puppetlabs/pdk/pull/344) ([bmjen](https://github.com/bmjen))
-  \(PDK-628\) Addition of module\_name question to interview [\#327](https://github.com/puppetlabs/pdk/pull/327) ([HelenCampbell](https://github.com/HelenCampbell))
- \(PDK-594\) mention the used template during `new module` [\#321](https://github.com/puppetlabs/pdk/pull/321) ([DavidS](https://github.com/DavidS))

**Fixed bugs:**

- add in readline support to ruby [\#305](https://github.com/puppetlabs/pdk/issues/305)
- \(PDK-643\) Disable non-exec validator spinners when noninteractive [\#385](https://github.com/puppetlabs/pdk/pull/385) ([rodjek](https://github.com/rodjek))
- \(PDK-596\) Accept "forgeuser-modulename" as argument to `new module`  [\#358](https://github.com/puppetlabs/pdk/pull/358) ([DavidS](https://github.com/DavidS))
- \(PDK-429\) Fix --tests to pass through to unit test handler. [\#351](https://github.com/puppetlabs/pdk/pull/351) ([bmjen](https://github.com/bmjen))

**Closed issues:**

- Internal Server Error on PDK Download site [\#348](https://github.com/puppetlabs/pdk/issues/348)
- PDK 1.2.1 `test unit` fails for unsupported OSes [\#338](https://github.com/puppetlabs/pdk/issues/338)

**Merged pull requests:**

- Release 1.3.0 [\#394](https://github.com/puppetlabs/pdk/pull/394) ([bmjen](https://github.com/bmjen))
- \(PDK-729\) Remove Set usage in metadata [\#393](https://github.com/puppetlabs/pdk/pull/393) ([rodjek](https://github.com/rodjek))
- \(maint\) Various UX fixes [\#391](https://github.com/puppetlabs/pdk/pull/391) ([bmjen](https://github.com/bmjen))
- Minor updates to convert dialog [\#390](https://github.com/puppetlabs/pdk/pull/390) ([HelenCampbell](https://github.com/HelenCampbell))
- \(maint\) pdk convert acceptance tests [\#389](https://github.com/puppetlabs/pdk/pull/389) ([rodjek](https://github.com/rodjek))
- \(maint\) Fixes module metadata interview to as for forge username [\#388](https://github.com/puppetlabs/pdk/pull/388) ([bmjen](https://github.com/bmjen))
- \(MAINT\) Update to released version of GCG [\#387](https://github.com/puppetlabs/pdk/pull/387) ([DavidS](https://github.com/DavidS))
- \(maint\) Manually load lib/pdk/version.rb in spec [\#386](https://github.com/puppetlabs/pdk/pull/386) ([rodjek](https://github.com/rodjek))
- \(PDK-489\) unhide experimental commands [\#384](https://github.com/puppetlabs/pdk/pull/384) ([DavidS](https://github.com/DavidS))
- \(PDK 719\) Directory layout and metadata fixes during convert [\#383](https://github.com/puppetlabs/pdk/pull/383) ([HelenCampbell](https://github.com/HelenCampbell))
- \(maint\) Some tweaks to improve UX. [\#382](https://github.com/puppetlabs/pdk/pull/382) ([bmjen](https://github.com/bmjen))
- \(PDK-722\) Remove prompt to continue from start of convert [\#378](https://github.com/puppetlabs/pdk/pull/378) ([rodjek](https://github.com/rodjek))
- \(PDK-728\) Add default\_template\_ref handler. [\#377](https://github.com/puppetlabs/pdk/pull/377) ([bmjen](https://github.com/bmjen))
- \(PDK-725\) Add timestamp to PDK Convert Report [\#376](https://github.com/puppetlabs/pdk/pull/376) ([bmjen](https://github.com/bmjen))
- \(PDK-724\) Ensure dir exist before writing new files during updates. [\#375](https://github.com/puppetlabs/pdk/pull/375) ([bmjen](https://github.com/bmjen))
- \(PDK-723\) Fixes bug where sync.yml wasn't being applied on convert [\#374](https://github.com/puppetlabs/pdk/pull/374) ([bmjen](https://github.com/bmjen))
- \(PDK-713\) Clean up old bundler env during convert [\#373](https://github.com/puppetlabs/pdk/pull/373) ([rodjek](https://github.com/rodjek))
- \(PDK-715\) Use correct module template branch/ref [\#368](https://github.com/puppetlabs/pdk/pull/368) ([bmjen](https://github.com/bmjen))
- Tweaks to dialog around module conversion [\#362](https://github.com/puppetlabs/pdk/pull/362) ([HelenCampbell](https://github.com/HelenCampbell))
- Additional user prompt [\#361](https://github.com/puppetlabs/pdk/pull/361) ([rickmonro](https://github.com/rickmonro))
- Making exit errors generic for interview qs [\#357](https://github.com/puppetlabs/pdk/pull/357) ([HelenCampbell](https://github.com/HelenCampbell))
- \(maint\) Update PDK::Test::Unit.parallel\_with\_no\_tests? for PSH \#216 changes [\#356](https://github.com/puppetlabs/pdk/pull/356) ([rodjek](https://github.com/rodjek))
- \(PDK-624\) Add UpdateManager class to handle making changes to module files [\#355](https://github.com/puppetlabs/pdk/pull/355) ([rodjek](https://github.com/rodjek))
- \(PDK-627\) Support for generating/updating metadata.json during convert [\#352](https://github.com/puppetlabs/pdk/pull/352) ([rodjek](https://github.com/rodjek))
- \(PDK-674\) UX Improvement for listing unit test files. [\#349](https://github.com/puppetlabs/pdk/pull/349) ([bmjen](https://github.com/bmjen))
- \(PDK-673\) Moving git commands into a util class [\#347](https://github.com/puppetlabs/pdk/pull/347) ([HelenCampbell](https://github.com/HelenCampbell))
- \(maint\) Fix generate/ and validate/ file layout to match namespace [\#345](https://github.com/puppetlabs/pdk/pull/345) ([rodjek](https://github.com/rodjek))
- \(PDK-626\) Templatedir can now handle multiple directories [\#340](https://github.com/puppetlabs/pdk/pull/340) ([HelenCampbell](https://github.com/HelenCampbell))
- \(maint\) Tidy up package test [\#337](https://github.com/puppetlabs/pdk/pull/337) ([james-stocks](https://github.com/james-stocks))
- \(PDK-621\) Implement a skeleton `pdk convert` command [\#335](https://github.com/puppetlabs/pdk/pull/335) ([rodjek](https://github.com/rodjek))

## [v1.2.1](https://github.com/puppetlabs/pdk/tree/v1.2.1) (2017-10-26)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.2.0...v1.2.1)

**Fixed bugs:**

- Add --relative cli argument for autoload layout testing in puppet-lint [\#325](https://github.com/puppetlabs/pdk/pull/325) ([spacepants](https://github.com/spacepants))

**Closed issues:**

- Create test layout for control repositories [\#332](https://github.com/puppetlabs/pdk/issues/332)
- Support for future parser on Puppet \< 4.0.0 [\#330](https://github.com/puppetlabs/pdk/issues/330)
- Expose other executables into main bin directory [\#328](https://github.com/puppetlabs/pdk/issues/328)
- PDK should have yum/apt/choco repos [\#324](https://github.com/puppetlabs/pdk/issues/324)
- Fails to create new task on OSX [\#316](https://github.com/puppetlabs/pdk/issues/316)
- Allow validation of control repos [\#289](https://github.com/puppetlabs/pdk/issues/289)

**Merged pull requests:**

- \(PDK-637\) Release 1.2.1 [\#334](https://github.com/puppetlabs/pdk/pull/334) ([bmjen](https://github.com/bmjen))
- \(PDK-408\) adjusts known issue in README [\#326](https://github.com/puppetlabs/pdk/pull/326) ([jbondpdx](https://github.com/jbondpdx))
- \(maint\) Bump version for 1.3.0 dev cycle [\#322](https://github.com/puppetlabs/pdk/pull/322) ([bmjen](https://github.com/bmjen))
- \(maint\) Add pdk-maintainers email to README [\#318](https://github.com/puppetlabs/pdk/pull/318) ([bmjen](https://github.com/bmjen))
- Fix link to PDK docs [\#317](https://github.com/puppetlabs/pdk/pull/317) ([turbodog](https://github.com/turbodog))

## [v1.2.0](https://github.com/puppetlabs/pdk/tree/v1.2.0) (2017-10-06)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.1.0...v1.2.0)

**Implemented enhancements:**

- \(PDK-479\) new module: create examples/, and files/ directory [\#308](https://github.com/puppetlabs/pdk/pull/308) ([DavidS](https://github.com/DavidS))
- \(PDK-470\) Validation of task metadata. [\#301](https://github.com/puppetlabs/pdk/pull/301) ([bmjen](https://github.com/bmjen))
- \(PDK-468\) `new task` command [\#299](https://github.com/puppetlabs/pdk/pull/299) ([rodjek](https://github.com/rodjek))

**Fixed bugs:**

- \(PDK-408\) Explain PowerShell escaping for -- on `bundle` [\#309](https://github.com/puppetlabs/pdk/pull/309) ([DavidS](https://github.com/DavidS))
- \(PDK-482\) Update help messages to be less ambiguous [\#307](https://github.com/puppetlabs/pdk/pull/307) ([DavidS](https://github.com/DavidS))
- \(PDK-555\) Handle windows style \(backslash separated\) paths when validating [\#306](https://github.com/puppetlabs/pdk/pull/306) ([rodjek](https://github.com/rodjek))
- \(PDK-543\) Fix spdx.org URLs in messages [\#303](https://github.com/puppetlabs/pdk/pull/303) ([farkasmate](https://github.com/farkasmate))
- \(PDK-502\) make the private git available to module commands [\#298](https://github.com/puppetlabs/pdk/pull/298) ([rodjek](https://github.com/rodjek))

**Closed issues:**

- Wrong URL in module interview [\#302](https://github.com/puppetlabs/pdk/issues/302)
- Installing Gemfile dependencies on Windows fails [\#297](https://github.com/puppetlabs/pdk/issues/297)

**Merged pull requests:**

- \(maint\) Update the default task support\_noop field to false [\#313](https://github.com/puppetlabs/pdk/pull/313) ([bmjen](https://github.com/bmjen))
- \(PDK-577\) Add info line that task metadata was also generated [\#312](https://github.com/puppetlabs/pdk/pull/312) ([DavidS](https://github.com/DavidS))
- \(PDK-554\) Release 1.2.0 [\#311](https://github.com/puppetlabs/pdk/pull/311) ([bmjen](https://github.com/bmjen))
- Tasks Generation and Validation [\#310](https://github.com/puppetlabs/pdk/pull/310) ([bmjen](https://github.com/bmjen))
- \(PDK-468\) Adding parameters field to task metadata [\#300](https://github.com/puppetlabs/pdk/pull/300) ([bmjen](https://github.com/bmjen))

## [v1.1.0](https://github.com/puppetlabs/pdk/tree/v1.1.0) (2017-09-13)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.0.1...v1.1.0)

**Implemented enhancements:**

- \(PDK-369\) Improve error context for pdk test unit failures [\#294](https://github.com/puppetlabs/pdk/pull/294) ([rodjek](https://github.com/rodjek))
- \(PDK-415\) Convert user-input related problems from FATAL to ERROR [\#293](https://github.com/puppetlabs/pdk/pull/293) ([rodjek](https://github.com/rodjek))
- \(PDK-465\) Improve output from spec\_prep/spec\_clean failures [\#290](https://github.com/puppetlabs/pdk/pull/290) ([rodjek](https://github.com/rodjek))
- \(PDK-465\) Add vendored git to PATH for package installs [\#287](https://github.com/puppetlabs/pdk/pull/287) ([rodjek](https://github.com/rodjek))
- \(PDK-370\) Adds a 'pdk module generate' redirect to 'pdk new module'. [\#286](https://github.com/puppetlabs/pdk/pull/286) ([bmjen](https://github.com/bmjen))
- \(PDK-459\) Improve error message when the generation target exists [\#285](https://github.com/puppetlabs/pdk/pull/285) ([DavidS](https://github.com/DavidS))
- \(PDK-461\) Update childprocess to current version [\#282](https://github.com/puppetlabs/pdk/pull/282) ([DavidS](https://github.com/DavidS))
- \(PDK-459\) Add defined type generator [\#280](https://github.com/puppetlabs/pdk/pull/280) ([rodjek](https://github.com/rodjek))
- \(MAINT\) Copy-edited all the user-visible messages [\#276](https://github.com/puppetlabs/pdk/pull/276) ([jbondpdx](https://github.com/jbondpdx))
- \(PDK-365\) Inform and prompt user following new module generate [\#270](https://github.com/puppetlabs/pdk/pull/270) ([bmjen](https://github.com/bmjen))
- \(maint\) Debug output GEM\_HOME and GEM\_PATH before executing module commands [\#268](https://github.com/puppetlabs/pdk/pull/268) ([james-stocks](https://github.com/james-stocks))
- \(SDK-336\) Add operating system question to the new module interview [\#262](https://github.com/puppetlabs/pdk/pull/262) ([rodjek](https://github.com/rodjek))

**Fixed bugs:**

- Remove EOL style cop from default configuration [\#267](https://github.com/puppetlabs/pdk/issues/267)
- \(PDK-450\) remove stdlib dependency [\#278](https://github.com/puppetlabs/pdk/pull/278) ([DavidS](https://github.com/DavidS))
- \(PDK-420\) Ensure Puppet and Puppet::Util modules are defined [\#277](https://github.com/puppetlabs/pdk/pull/277) ([rodjek](https://github.com/rodjek))
- \(PDK-430\) Do not cache template-url answer if using the default template [\#265](https://github.com/puppetlabs/pdk/pull/265) ([rodjek](https://github.com/rodjek))

**Closed issues:**

- Write .fixtures.yml based on metadata.json [\#283](https://github.com/puppetlabs/pdk/issues/283)
- Default Gemfile for new module need linting [\#273](https://github.com/puppetlabs/pdk/issues/273)
- pdk executable not installed in path on Debian \(8.8 Jessie\) [\#272](https://github.com/puppetlabs/pdk/issues/272)
- File mode of generated files and directories are wrong [\#271](https://github.com/puppetlabs/pdk/issues/271)
- Missing bins should not be fatal [\#253](https://github.com/puppetlabs/pdk/issues/253)

**Merged pull requests:**

- \(maint\) Sync Windows api types with latest puppet. [\#296](https://github.com/puppetlabs/pdk/pull/296) ([bmjen](https://github.com/bmjen))
- Release v1.1.0 [\#295](https://github.com/puppetlabs/pdk/pull/295) ([bmjen](https://github.com/bmjen))
- \(PDK-459\) Docs for generating defined\_type [\#292](https://github.com/puppetlabs/pdk/pull/292) ([bmjen](https://github.com/bmjen))
- \(MAINT\) Run package test commands in a login shell [\#284](https://github.com/puppetlabs/pdk/pull/284) ([scotje](https://github.com/scotje))
- \(PDK-461\) Make Version.git\_ref more forgiving [\#281](https://github.com/puppetlabs/pdk/pull/281) ([DavidS](https://github.com/DavidS))
- \(PDK-446\) Package tests should expect pdk to already be on path [\#279](https://github.com/puppetlabs/pdk/pull/279) ([james-stocks](https://github.com/james-stocks))
- \(MAINT\) Add strings to POT file [\#269](https://github.com/puppetlabs/pdk/pull/269) ([austb](https://github.com/austb))
- \(maint\) Updates version to 1.1.0.pre [\#264](https://github.com/puppetlabs/pdk/pull/264) ([bmjen](https://github.com/bmjen))

## [v1.0.1](https://github.com/puppetlabs/pdk/tree/v1.0.1) (2017-08-17)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v1.0.0...v1.0.1)

**Fixed bugs:**

- \(MAINT\) Add package bin path to subprocess PATH [\#261](https://github.com/puppetlabs/pdk/pull/261) ([austb](https://github.com/austb))
- \(MAINT\) Bump tty-prompt ver, remove monkey patch [\#260](https://github.com/puppetlabs/pdk/pull/260) ([austb](https://github.com/austb))

**Merged pull requests:**

- Release Prep for 1.0.1 [\#263](https://github.com/puppetlabs/pdk/pull/263) ([bmjen](https://github.com/bmjen))
- \(MAINT\) Bump master version to 1.1.0.pre [\#259](https://github.com/puppetlabs/pdk/pull/259) ([bmjen](https://github.com/bmjen))
- Formatting fix [\#258](https://github.com/puppetlabs/pdk/pull/258) ([turbodog](https://github.com/turbodog))

## [v1.0.0](https://github.com/puppetlabs/pdk/tree/v1.0.0) (2017-08-15)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.6.0...v1.0.0)

**Implemented enhancements:**

- \(PDK-395\) Use vendored pdk-module-template repo when available [\#255](https://github.com/puppetlabs/pdk/pull/255) ([scotje](https://github.com/scotje))
- Move content from README to official docs site [\#252](https://github.com/puppetlabs/pdk/pull/252) ([jbondpdx](https://github.com/jbondpdx))
- \(PDK-367\) Update questionnaire wording [\#251](https://github.com/puppetlabs/pdk/pull/251) ([DavidS](https://github.com/DavidS))
- \(PDK-406\) Add GEM\_HOME and GEM\_PATH bin dirs to PATH when executing commands [\#249](https://github.com/puppetlabs/pdk/pull/249) ([rodjek](https://github.com/rodjek))
- \(PDK-401, PDK-402, PDK-403, PDK-404\) Update validators to handle targets better [\#248](https://github.com/puppetlabs/pdk/pull/248) ([bmjen](https://github.com/bmjen))
- \(maint\) Allow bundler to install gems in parallel [\#245](https://github.com/puppetlabs/pdk/pull/245) ([james-stocks](https://github.com/james-stocks))
- \(PDK-397\) Log output of bundler commands at appropriate levels [\#243](https://github.com/puppetlabs/pdk/pull/243) ([scotje](https://github.com/scotje))
- \(PDK-396\) Disable spinners in debug mode [\#233](https://github.com/puppetlabs/pdk/pull/233) ([rodjek](https://github.com/rodjek))
- \(PDK-388, PDK-392\) Add README, CHANGELOG, and puppet requirement to module generation [\#232](https://github.com/puppetlabs/pdk/pull/232) ([bmjen](https://github.com/bmjen))
- \(SDK-144\) Add option to run validate in parallel [\#144](https://github.com/puppetlabs/pdk/pull/144) ([austb](https://github.com/austb))

**Fixed bugs:**

- Running PDK native packages on Windows under ConEmu fails [\#220](https://github.com/puppetlabs/pdk/issues/220)
- \(PDK-407\) Validate module interview confirmation answer [\#237](https://github.com/puppetlabs/pdk/pull/237) ([rodjek](https://github.com/rodjek))
- \(PDK-386\) Remove parameter options from 'new class' [\#236](https://github.com/puppetlabs/pdk/pull/236) ([austb](https://github.com/austb))

**Merged pull requests:**

- \(maint\) monkey patch TTY::Prompt::Reader::WinConsole to make it blocking [\#257](https://github.com/puppetlabs/pdk/pull/257) ([rodjek](https://github.com/rodjek))
- \(MAINT\) Release prep for 1.0.0 [\#256](https://github.com/puppetlabs/pdk/pull/256) ([scotje](https://github.com/scotje))
- \(MAINT\) temporarily remove de translation [\#250](https://github.com/puppetlabs/pdk/pull/250) ([DavidS](https://github.com/DavidS))
- \(MAINT\) Bump master version to 1.0.0.pre [\#244](https://github.com/puppetlabs/pdk/pull/244) ([scotje](https://github.com/scotje))
- \(FIXUP\) Prevent unit tests from writing results.txt to real filesystem [\#242](https://github.com/puppetlabs/pdk/pull/242) ([scotje](https://github.com/scotje))
- \(MAINT\) Don't check coverage on gitignored files [\#241](https://github.com/puppetlabs/pdk/pull/241) ([scotje](https://github.com/scotje))
- \(MAINT\) Use non-forked tty-prompt gem [\#240](https://github.com/puppetlabs/pdk/pull/240) ([austb](https://github.com/austb))
- \(MAINT\) Add ISC to approved licenses [\#238](https://github.com/puppetlabs/pdk/pull/238) ([scotje](https://github.com/scotje))
- \(maint\) add license auditing to travis [\#205](https://github.com/puppetlabs/pdk/pull/205) ([DavidS](https://github.com/DavidS))

## [v0.6.0](https://github.com/puppetlabs/pdk/tree/v0.6.0) (2017-08-08)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.5.0...v0.6.0)

**Implemented enhancements:**

- \(MAINT\) Improve moduleroot error message [\#224](https://github.com/puppetlabs/pdk/pull/224) ([DavidS](https://github.com/DavidS))
- \(MAINT\) workaround rspec-puppt-facts being case-sensitive for operatingsystem filters [\#222](https://github.com/puppetlabs/pdk/pull/222) ([DavidS](https://github.com/DavidS))
- \(PDK-354\) Change PDK::Logger to write to STDERR [\#217](https://github.com/puppetlabs/pdk/pull/217) ([scotje](https://github.com/scotje))
- \(SDK-331\) Use vendored Gemfile.lock when available and needed [\#215](https://github.com/puppetlabs/pdk/pull/215) ([scotje](https://github.com/scotje))
- \(maint\) Expose message when FileUtils.mkdir\_p fails during module generation [\#209](https://github.com/puppetlabs/pdk/pull/209) ([rodjek](https://github.com/rodjek))
- \(SDK-323\) Change color of default answer to cyan [\#206](https://github.com/puppetlabs/pdk/pull/206) ([austb](https://github.com/austb))
- \(maint\) Remove unimplemented `add provider` from docs [\#200](https://github.com/puppetlabs/pdk/pull/200) ([DavidS](https://github.com/DavidS))
- Update PowerShell install instructions [\#194](https://github.com/puppetlabs/pdk/pull/194) ([jpogran](https://github.com/jpogran))
- \(maint\) Remove unused vcs option from 'pdk new module' [\#192](https://github.com/puppetlabs/pdk/pull/192) ([rodjek](https://github.com/rodjek))
- Document compatibility policy and upgrade strategy [\#188](https://github.com/puppetlabs/pdk/pull/188) ([turbodog](https://github.com/turbodog))
- \(MAINT\) Remove spinner for `bundle check` command [\#187](https://github.com/puppetlabs/pdk/pull/187) ([scotje](https://github.com/scotje))
- \(SDK-321\) add `pdk validate help` [\#183](https://github.com/puppetlabs/pdk/pull/183) ([DavidS](https://github.com/DavidS))
- \(SDK-317\) Ensure parent of 'pdk new module' is writable before generation [\#175](https://github.com/puppetlabs/pdk/pull/175) ([rodjek](https://github.com/rodjek))
- \(SDK-312\) Add option --parallel to `pdk test unit` [\#154](https://github.com/puppetlabs/pdk/pull/154) ([austb](https://github.com/austb))

**Fixed bugs:**

- \(SDK-325\) Validate all should run all validators [\#230](https://github.com/puppetlabs/pdk/pull/230) ([bmjen](https://github.com/bmjen))
- \(PDK-373\) Make test unit --list consistent with test unit [\#216](https://github.com/puppetlabs/pdk/pull/216) ([james-stocks](https://github.com/james-stocks))
- \(MAINT\) Add --strict-dependencies to metadata-json-lint invocation [\#213](https://github.com/puppetlabs/pdk/pull/213) ([scotje](https://github.com/scotje))
- \(SDK-317\) Replace File.writable? test with actually creating a test file [\#207](https://github.com/puppetlabs/pdk/pull/207) ([scotje](https://github.com/scotje))
- \(SDK-333\) Rescue Interrupt cleanly [\#199](https://github.com/puppetlabs/pdk/pull/199) ([scotje](https://github.com/scotje))
- \(\#137\) Nicer response when binary doesn't exist [\#149](https://github.com/puppetlabs/pdk/pull/149) ([rodjek](https://github.com/rodjek))

**Closed issues:**

- Add /bin/ to .gitignore [\#208](https://github.com/puppetlabs/pdk/issues/208)
- How to run beaker with pdk? [\#138](https://github.com/puppetlabs/pdk/issues/138)
- Failed to create new module with "No such file or directory - git" [\#137](https://github.com/puppetlabs/pdk/issues/137)

**Merged pull requests:**

- \(MAINT\) Release prep for 0.6.0 [\#231](https://github.com/puppetlabs/pdk/pull/231) ([scotje](https://github.com/scotje))
- Enable rubocop for package-testing folder [\#229](https://github.com/puppetlabs/pdk/pull/229) ([james-stocks](https://github.com/james-stocks))
- \(PDK-390\) Implement spec:coverage rake task [\#228](https://github.com/puppetlabs/pdk/pull/228) ([DavidS](https://github.com/DavidS))
- \(MAINT\) Re-add package acceptance test for Gemfile.lock vendoring [\#226](https://github.com/puppetlabs/pdk/pull/226) ([scotje](https://github.com/scotje))
- \(PDK-385\) Support package testing on OSX [\#225](https://github.com/puppetlabs/pdk/pull/225) ([james-stocks](https://github.com/james-stocks))
- Pdk preview docs [\#223](https://github.com/puppetlabs/pdk/pull/223) ([jbondpdx](https://github.com/jbondpdx))
- Package testing: beaker needs to have keys configured [\#221](https://github.com/puppetlabs/pdk/pull/221) ([james-stocks](https://github.com/james-stocks))
- \(MAINT\) Add find\_all and find\_first json functions [\#219](https://github.com/puppetlabs/pdk/pull/219) ([austb](https://github.com/austb))
- \(MAINT\) Fix fatal error in test unit --parallel [\#218](https://github.com/puppetlabs/pdk/pull/218) ([austb](https://github.com/austb))
- \(MAINT\) Add ability to test locally built package with beaker [\#214](https://github.com/puppetlabs/pdk/pull/214) ([scotje](https://github.com/scotje))
- Give beaker package tests their own Gemfile [\#212](https://github.com/puppetlabs/pdk/pull/212) ([james-stocks](https://github.com/james-stocks))
- \(MAINT\) Update to official master of github-changelog-generator [\#211](https://github.com/puppetlabs/pdk/pull/211) ([DavidS](https://github.com/DavidS))
- Unit test baseline [\#210](https://github.com/puppetlabs/pdk/pull/210) ([james-stocks](https://github.com/james-stocks))
- \(maint\) Add unit tests for PDK::Util [\#204](https://github.com/puppetlabs/pdk/pull/204) ([rodjek](https://github.com/rodjek))
- \(maint\) Finish unit tests for PDK::Generate::PuppetObject [\#203](https://github.com/puppetlabs/pdk/pull/203) ([rodjek](https://github.com/rodjek))
- \(maint\) Add unit test for PDK.logger [\#202](https://github.com/puppetlabs/pdk/pull/202) ([rodjek](https://github.com/rodjek))
- \(maint\) enable coveralls [\#201](https://github.com/puppetlabs/pdk/pull/201) ([DavidS](https://github.com/DavidS))
- \(MAINT\) Add YARD gem and rake task [\#197](https://github.com/puppetlabs/pdk/pull/197) ([austb](https://github.com/austb))
- \(MAINT\) Replace \#sort.last with \#max [\#196](https://github.com/puppetlabs/pdk/pull/196) ([austb](https://github.com/austb))
- \(SDK-313\) Update acceptance tests following audit [\#193](https://github.com/puppetlabs/pdk/pull/193) ([james-stocks](https://github.com/james-stocks))
- \(MAINT\) Move all unit tests under spec/unit [\#190](https://github.com/puppetlabs/pdk/pull/190) ([scotje](https://github.com/scotje))
- \(MAINT\) Bump version to 0.6.0.pre [\#186](https://github.com/puppetlabs/pdk/pull/186) ([scotje](https://github.com/scotje))
- Clarity on running pdk from PowerShell [\#185](https://github.com/puppetlabs/pdk/pull/185) ([turbodog](https://github.com/turbodog))
- \(maint\) Change package testing to beaker tests [\#184](https://github.com/puppetlabs/pdk/pull/184) ([james-stocks](https://github.com/james-stocks))
- \(maint\) Move contributor's notes to separate file [\#181](https://github.com/puppetlabs/pdk/pull/181) ([DavidS](https://github.com/DavidS))

## [v0.5.0](https://github.com/puppetlabs/pdk/tree/v0.5.0) (2017-07-20)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.4.4...v0.5.0)

**Implemented enhancements:**

- \(SDK-329\) implement running arbitrary commands in PDK's environment [\#179](https://github.com/puppetlabs/pdk/pull/179) ([DavidS](https://github.com/DavidS))
- \(maint\) Add 2.1.9 as the minimum required ruby version in the gemspec [\#176](https://github.com/puppetlabs/pdk/pull/176) ([rodjek](https://github.com/rodjek))

**Fixed bugs:**

- \(SDK-331\) allow additional gems to be installed [\#178](https://github.com/puppetlabs/pdk/pull/178) ([DavidS](https://github.com/DavidS))

**Merged pull requests:**

- \(maint\) Release prep for 0.5.0 [\#180](https://github.com/puppetlabs/pdk/pull/180) ([DavidS](https://github.com/DavidS))
- \(SDK-322\) Acceptance test for spec tests of new class [\#177](https://github.com/puppetlabs/pdk/pull/177) ([james-stocks](https://github.com/james-stocks))
- \(MAINT\) Bump to 0.5.0.pre [\#174](https://github.com/puppetlabs/pdk/pull/174) ([scotje](https://github.com/scotje))
- \(maint\) Finish PDK::Validate::\* unit tests [\#139](https://github.com/puppetlabs/pdk/pull/139) ([rodjek](https://github.com/rodjek))

## [v0.4.4](https://github.com/puppetlabs/pdk/tree/v0.4.4) (2017-07-18)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.4.3...v0.4.4)

**Fixed bugs:**

- Cannot find bundler [\#166](https://github.com/puppetlabs/pdk/issues/166)
- Validate fails on existing module [\#158](https://github.com/puppetlabs/pdk/issues/158)
- \(\#158\) \(\#166\) Resolve issue loading bundler from gem installs [\#170](https://github.com/puppetlabs/pdk/pull/170) ([scotje](https://github.com/scotje))
- \(SDK-319\) force usage of our ruby [\#168](https://github.com/puppetlabs/pdk/pull/168) ([DavidS](https://github.com/DavidS))

**Closed issues:**

- `new module` docs differ from reality [\#159](https://github.com/puppetlabs/pdk/issues/159)

**Merged pull requests:**

- \(MAINT\) Release prep for 0.4.4 [\#173](https://github.com/puppetlabs/pdk/pull/173) ([scotje](https://github.com/scotje))
- \(maint\) mention the execution policy for windows [\#172](https://github.com/puppetlabs/pdk/pull/172) ([DavidS](https://github.com/DavidS))
- \(maint\) update README to point to current download location [\#171](https://github.com/puppetlabs/pdk/pull/171) ([DavidS](https://github.com/DavidS))
- \(maint\) fix `new module` description in README [\#169](https://github.com/puppetlabs/pdk/pull/169) ([DavidS](https://github.com/DavidS))

## [v0.4.3](https://github.com/puppetlabs/pdk/tree/v0.4.3) (2017-07-17)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.4.2...v0.4.3)

**Fixed bugs:**

- \(FIXUP\) Fix default subprocess success/failure messages on Windows [\#164](https://github.com/puppetlabs/pdk/pull/164) ([scotje](https://github.com/scotje))

**Merged pull requests:**

- \(MAINT\) Release prep 0.4.3 [\#165](https://github.com/puppetlabs/pdk/pull/165) ([scotje](https://github.com/scotje))
- \(MAINT\) Re-bump version to 0.5.0.pre [\#163](https://github.com/puppetlabs/pdk/pull/163) ([scotje](https://github.com/scotje))

## [v0.4.2](https://github.com/puppetlabs/pdk/tree/v0.4.2) (2017-07-17)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.4.1...v0.4.2)

**Fixed bugs:**

- Can't create module if new module fails to get login [\#157](https://github.com/puppetlabs/pdk/issues/157)
- \(FIXUP\) Add missing newlines in new module interview prompts [\#161](https://github.com/puppetlabs/pdk/pull/161) ([scotje](https://github.com/scotje))
- Use default username when Etc.getlogin fails [\#160](https://github.com/puppetlabs/pdk/pull/160) ([austb](https://github.com/austb))

**Merged pull requests:**

- \(MAINT\) Release prep for 0.4.2 [\#162](https://github.com/puppetlabs/pdk/pull/162) ([scotje](https://github.com/scotje))
- \(maint\) Remove beaker pre-suite for updating rubygems [\#156](https://github.com/puppetlabs/pdk/pull/156) ([james-stocks](https://github.com/james-stocks))
- \(maint\) Bumps version for next dev cycle. [\#152](https://github.com/puppetlabs/pdk/pull/152) ([bmjen](https://github.com/bmjen))

## [v0.4.1](https://github.com/puppetlabs/pdk/tree/v0.4.1) (2017-07-14)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.4.0...v0.4.1)

**Fixed bugs:**

- \(FIXUP\) Resolve conflation of cachedir concepts [\#153](https://github.com/puppetlabs/pdk/pull/153) ([scotje](https://github.com/scotje))

**Merged pull requests:**

- Release prep 0.4.1 [\#155](https://github.com/puppetlabs/pdk/pull/155) ([scotje](https://github.com/scotje))

## [v0.4.0](https://github.com/puppetlabs/pdk/tree/v0.4.0) (2017-07-14)
[Full Changelog](https://github.com/puppetlabs/pdk/compare/v0.3.0...v0.4.0)

**Implemented enhancements:**

- \(SDK-306\) Use vendored development gems in package install [\#145](https://github.com/puppetlabs/pdk/pull/145) ([scotje](https://github.com/scotje))
- \(SDK-299\) Check metadata.json syntax before linting [\#133](https://github.com/puppetlabs/pdk/pull/133) ([rodjek](https://github.com/rodjek))
- \(SDK-305\) Answer file to cache module interview answers, template-url etc [\#132](https://github.com/puppetlabs/pdk/pull/132) ([rodjek](https://github.com/rodjek))
- \(SDK-296\) Allow target selection for the metadata validator [\#124](https://github.com/puppetlabs/pdk/pull/124) ([rodjek](https://github.com/rodjek))

**Fixed bugs:**

- \(maint\) Remove nil values from metadata before generating JSON [\#127](https://github.com/puppetlabs/pdk/pull/127) ([rodjek](https://github.com/rodjek))
- \(SDK-298\) Handle exception raised when an invalid report format is specified on the CLI [\#125](https://github.com/puppetlabs/pdk/pull/125) ([rodjek](https://github.com/rodjek))

**Merged pull requests:**

- v0.4.0 Release Prep [\#151](https://github.com/puppetlabs/pdk/pull/151) ([bmjen](https://github.com/bmjen))
- \(FIXUP\) Fixes spec tests for answer\_file [\#150](https://github.com/puppetlabs/pdk/pull/150) ([bmjen](https://github.com/bmjen))
- \(maint\) Pin activesupport to the last release that supported Ruby 2.1.9 [\#148](https://github.com/puppetlabs/pdk/pull/148) ([bmjen](https://github.com/bmjen))
- \(FIXUP\) Change rubocop default json\_data to a hash [\#147](https://github.com/puppetlabs/pdk/pull/147) ([scotje](https://github.com/scotje))
- \(FIXUP\) Flatten parsed JSON output from puppet-lint before processing [\#146](https://github.com/puppetlabs/pdk/pull/146) ([scotje](https://github.com/scotje))
- \(maint\) Improvements to acceptance testing packages [\#142](https://github.com/puppetlabs/pdk/pull/142) ([james-stocks](https://github.com/james-stocks))
- Acceptance tidy-up [\#140](https://github.com/puppetlabs/pdk/pull/140) ([james-stocks](https://github.com/james-stocks))
- removes some incorrect info from README [\#136](https://github.com/puppetlabs/pdk/pull/136) ([jbondpdx](https://github.com/jbondpdx))
- \(maint\) Changes sdk references to pdk [\#135](https://github.com/puppetlabs/pdk/pull/135) ([bmjen](https://github.com/bmjen))
- \(SDK-275\) Run tests against VM with package install [\#134](https://github.com/puppetlabs/pdk/pull/134) ([james-stocks](https://github.com/james-stocks))
- \(maint\) Extend unit tests for PDK::Util::Bundler [\#131](https://github.com/puppetlabs/pdk/pull/131) ([rodjek](https://github.com/rodjek))
- \(maint\) Add missing unit tests for PDK::Report::Event [\#130](https://github.com/puppetlabs/pdk/pull/130) ([rodjek](https://github.com/rodjek))
- \(maint\) Add unit tests for 'pdk new class' CLI [\#129](https://github.com/puppetlabs/pdk/pull/129) ([rodjek](https://github.com/rodjek))
- \(maint\) Finish off PDK::CLI::Validate unit tests [\#128](https://github.com/puppetlabs/pdk/pull/128) ([rodjek](https://github.com/rodjek))
- \(maint\) Updating version for new dev cycle [\#126](https://github.com/puppetlabs/pdk/pull/126) ([bmjen](https://github.com/bmjen))
- \(maint\) Performance improvements [\#120](https://github.com/puppetlabs/pdk/pull/120) ([rodjek](https://github.com/rodjek))
- \(idea\) More expressive RSpec matchers for JUnit XML content [\#117](https://github.com/puppetlabs/pdk/pull/117) ([rodjek](https://github.com/rodjek))

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

**Closed issues:**

- Function: pdk new module my\_module does not work when a user name contains non-alphanumeric characters [\#106](https://github.com/puppetlabs/pdk/issues/106)

**Merged pull requests:**

- v0.3.0 Release Prep. [\#123](https://github.com/puppetlabs/pdk/pull/123) ([bmjen](https://github.com/bmjen))
- \(maint\) Remove incorrect space character in README [\#122](https://github.com/puppetlabs/pdk/pull/122) ([james-stocks](https://github.com/james-stocks))
- \(SDK-294\) Avoid module name conflict in acceptance tests. [\#121](https://github.com/puppetlabs/pdk/pull/121) ([james-stocks](https://github.com/james-stocks))
- \(maint\) Add release instructions [\#118](https://github.com/puppetlabs/pdk/pull/118) ([DavidS](https://github.com/DavidS))
- \(maint\) Support for skipped/pending tests [\#115](https://github.com/puppetlabs/pdk/pull/115) ([james-stocks](https://github.com/james-stocks))
- \(maint\) Update validate CLI help text & README [\#114](https://github.com/puppetlabs/pdk/pull/114) ([rodjek](https://github.com/rodjek))
- \(maint\) Make binstub generation quiet unless it fails [\#113](https://github.com/puppetlabs/pdk/pull/113) ([rodjek](https://github.com/rodjek))
- Cleanup rubocop todos [\#110](https://github.com/puppetlabs/pdk/pull/110) ([rodjek](https://github.com/rodjek))
- \(SDK-260\) Acceptance tests for puppet-lint integration [\#109](https://github.com/puppetlabs/pdk/pull/109) ([rodjek](https://github.com/rodjek))
- \(maint\) update bundler on travis to current version [\#101](https://github.com/puppetlabs/pdk/pull/101) ([DavidS](https://github.com/DavidS))
- \(SDK-256\) Acceptance tests for metadata validator behavior and output [\#99](https://github.com/puppetlabs/pdk/pull/99) ([rodjek](https://github.com/rodjek))

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

**Closed issues:**

- create\_process error on windows when creating a new module [\#73](https://github.com/puppetlabs/pdk/issues/73)

**Merged pull requests:**

- \(maint\) Release 0.2.0 [\#97](https://github.com/puppetlabs/pdk/pull/97) ([DavidS](https://github.com/DavidS))
- \(SDK-245\) Add acceptance tests for the output of the ruby validator [\#96](https://github.com/puppetlabs/pdk/pull/96) ([rodjek](https://github.com/rodjek))
- \(SDK-247\) Add tests for rubocop target selection [\#95](https://github.com/puppetlabs/pdk/pull/95) ([rodjek](https://github.com/rodjek))
- \(maint\) update travis badge to public instance [\#93](https://github.com/puppetlabs/pdk/pull/93) ([DavidS](https://github.com/DavidS))
- \(maint\) Guard PDK::Util::Bundle.ensure\_bundle! to only run once [\#91](https://github.com/puppetlabs/pdk/pull/91) ([rodjek](https://github.com/rodjek))
- \(maint\) release prep prep [\#89](https://github.com/puppetlabs/pdk/pull/89) ([DavidS](https://github.com/DavidS))
- \(MAINT\) Create a class-based subprocess executor. [\#88](https://github.com/puppetlabs/pdk/pull/88) ([scotje](https://github.com/scotje))
- \(maint\) Fixes travis-ci hipchat notifications [\#85](https://github.com/puppetlabs/pdk/pull/85) ([bmjen](https://github.com/bmjen))
- \(maint\) Rubocop rake task, and shared context [\#84](https://github.com/puppetlabs/pdk/pull/84) ([DavidS](https://github.com/DavidS))
- \(SDK-244\) Add basic ruby validation acceptance tests. [\#83](https://github.com/puppetlabs/pdk/pull/83) ([DavidS](https://github.com/DavidS))
- \(maint\) Expand Windows 8.3 paths in templatedir [\#82](https://github.com/puppetlabs/pdk/pull/82) ([james-stocks](https://github.com/james-stocks))
- Report format implementation [\#81](https://github.com/puppetlabs/pdk/pull/81) ([rodjek](https://github.com/rodjek))
- \(FIXUP\) Add a GEM\_PATH for bundler when running acceptance tests [\#80](https://github.com/puppetlabs/pdk/pull/80) ([scotje](https://github.com/scotje))
- Naming fix [\#79](https://github.com/puppetlabs/pdk/pull/79) ([turbodog](https://github.com/turbodog))
- \(SDK-276\) Rubocop rules and cleanup [\#78](https://github.com/puppetlabs/pdk/pull/78) ([DavidS](https://github.com/DavidS))
- \(maint\) Windows cache folder should not be roaming [\#77](https://github.com/puppetlabs/pdk/pull/77) ([james-stocks](https://github.com/james-stocks))
- \(SDK-190\) Acceptance tests for using commands outside module folder [\#76](https://github.com/puppetlabs/pdk/pull/76) ([james-stocks](https://github.com/james-stocks))
- \(FIXUP\) Fixes module\_root typo and validate nil handling [\#72](https://github.com/puppetlabs/pdk/pull/72) ([bmjen](https://github.com/bmjen))
- \(SDK-269\) Add acceptance tests for bundle management. [\#68](https://github.com/puppetlabs/pdk/pull/68) ([scotje](https://github.com/scotje))
- \(maint\) refactor CLI initialisation to recommended CRI pattern [\#67](https://github.com/puppetlabs/pdk/pull/67) ([DavidS](https://github.com/DavidS))
- \(SDK-197\) add acceptance tests for new class command [\#65](https://github.com/puppetlabs/pdk/pull/65) ([DavidS](https://github.com/DavidS))
- \(SDK-218\) Prepare for CI tests against built packages [\#64](https://github.com/puppetlabs/pdk/pull/64) ([james-stocks](https://github.com/james-stocks))
- Relax data type validation to warn when non-standard types used [\#59](https://github.com/puppetlabs/pdk/pull/59) ([rodjek](https://github.com/rodjek))

## [v0.1.0](https://github.com/puppetlabs/pdk/tree/v0.1.0) (2017-06-05)
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

**Merged pull requests:**

- \(maint\) Add CI badges to README [\#57](https://github.com/puppetlabs/pdk/pull/57) ([james-stocks](https://github.com/james-stocks))
- \(maint\) Add local acceptance tests to Github CI [\#55](https://github.com/puppetlabs/pdk/pull/55) ([james-stocks](https://github.com/james-stocks))
- \(MAINT\) Ignore bundler generated binstubs but keep bin/\(setup|console\) [\#54](https://github.com/puppetlabs/pdk/pull/54) ([scotje](https://github.com/scotje))
- Fixes to acceptance [\#53](https://github.com/puppetlabs/pdk/pull/53) ([james-stocks](https://github.com/james-stocks))
- \(SDK-259\) Add NOTICE file [\#50](https://github.com/puppetlabs/pdk/pull/50) ([DavidS](https://github.com/DavidS))
- \(SDK-223\) Allow running acceptance tests against current checkout [\#49](https://github.com/puppetlabs/pdk/pull/49) ([james-stocks](https://github.com/james-stocks))
- \(SDK-222\) Enable rubocop checking in travis [\#44](https://github.com/puppetlabs/pdk/pull/44) ([james-stocks](https://github.com/james-stocks))
- \(MAINT\) Fixup usage of Tempfile in PDK::CLI::Exec [\#39](https://github.com/puppetlabs/pdk/pull/39) ([scotje](https://github.com/scotje))
- \(maint\) Rephrase and tighten CLI spec test [\#38](https://github.com/puppetlabs/pdk/pull/38) ([DavidS](https://github.com/DavidS))
- \(SDK-217\) Prepare acceptance testing for CI [\#37](https://github.com/puppetlabs/pdk/pull/37) ([james-stocks](https://github.com/james-stocks))
- \(maint, l10n, de\) remove obsolete msgids [\#36](https://github.com/puppetlabs/pdk/pull/36) ([DavidS](https://github.com/DavidS))
- \(MAINT\) Add Appveyor HipChat config. [\#34](https://github.com/puppetlabs/pdk/pull/34) ([scotje](https://github.com/scotje))
- \(MAINT\) Add Hipchat notifications to Travis config. [\#33](https://github.com/puppetlabs/pdk/pull/33) ([scotje](https://github.com/scotje))
- \(SDK-195\) Initial commit of acceptance spec tests [\#29](https://github.com/puppetlabs/pdk/pull/29) ([james-stocks](https://github.com/james-stocks))
- \(MAINT\) Remove Ruby 2.3.x heredoc syntax usage and add 2.1.9 to travis. [\#25](https://github.com/puppetlabs/pdk/pull/25) ([scotje](https://github.com/scotje))
- \(maint\) SDK to Puppet Development Kit naming change [\#21](https://github.com/puppetlabs/pdk/pull/21) ([whopper](https://github.com/whopper))
- \(MAINT\) Rename "generate provider" to "add provider" in README. [\#17](https://github.com/puppetlabs/pdk/pull/17) ([scotje](https://github.com/scotje))
- \(SDK-120\) Remove old Pick logo [\#16](https://github.com/puppetlabs/pdk/pull/16) ([whopper](https://github.com/whopper))
- \(SDK-120\) Add skeleton for unit test subcommand [\#15](https://github.com/puppetlabs/pdk/pull/15) ([whopper](https://github.com/whopper))
- \(PDK-176\) Rename Pick to PDK [\#14](https://github.com/puppetlabs/pdk/pull/14) ([whopper](https://github.com/whopper))
- \(MAINT\) Add basic logging facility. [\#13](https://github.com/puppetlabs/pdk/pull/13) ([scotje](https://github.com/scotje))
- \(MAINT\) Update Pick::Report specs to use and clean up a tmpdir. [\#12](https://github.com/puppetlabs/pdk/pull/12) ([scotje](https://github.com/scotje))
- \(MAINT\) Minor adjustments to CLI setup. [\#11](https://github.com/puppetlabs/pdk/pull/11) ([scotje](https://github.com/scotje))
- \(SDK-105\) Add Cri option parsing and static analysis functionality [\#10](https://github.com/puppetlabs/pdk/pull/10) ([whopper](https://github.com/whopper))
- \(maint\) Tidy up Gemfile [\#8](https://github.com/puppetlabs/pdk/pull/8) ([james-stocks](https://github.com/james-stocks))
- \(SDK-99\) Enable travis and appveyor spec tests [\#7](https://github.com/puppetlabs/pdk/pull/7) ([james-stocks](https://github.com/james-stocks))
- Remove 'Code Management' section. [\#6](https://github.com/puppetlabs/pdk/pull/6) ([scotje](https://github.com/scotje))
- Rename 'test static' to 'validate' and refine [\#4](https://github.com/puppetlabs/pdk/pull/4) ([scotje](https://github.com/scotje))
- Rename 'generate module' to 'new' [\#2](https://github.com/puppetlabs/pdk/pull/2) ([scotje](https://github.com/scotje))
- for review: \(docs\) first edit on pick README [\#1](https://github.com/puppetlabs/pdk/pull/1) ([jbondpdx](https://github.com/jbondpdx))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*