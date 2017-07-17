{
  helper: 'package-testing/lib/helper.rb',
  pre_suite: [
    'package-testing/pre/000_install_package.rb',
    'package-testing/pre/010_copy_tests_to_sut.rb',
  ],
  post_suite: [
    'package-testing/post/000_archive_results.rb',
  ],
}
