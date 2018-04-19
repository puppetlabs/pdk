test_name 'Test puppet & ruby version selection' do
  require 'pdk/pdk_helper.rb'

  module_name = 'version_selection'

  teardown do
    on(workstation, "rm -rf #{module_name}") if module_name
  end

  step 'Create a module' do
    on(workstation, pdk_command(workstation, "new module #{module_name} --skip-interview"))
  end

  test_cases = [
    { envvar: 'PDK_PUPPET_VERSION', version: '5.5.0', expected_puppet: '5.5', expected_ruby: '2.4.3' },
    { envvar: 'PDK_PUPPET_VERSION', version: '4.10.10', expected_puppet: '4.10', expected_ruby: '2.1.9' },
    { envvar: 'PDK_PE_VERSION', version: '2017.3', expected_puppet: '5.3', expected_ruby: '2.4.3' },
    { envvar: 'PDK_PE_VERSION', version: '2017.2', expected_puppet: '4.10', expected_ruby: '2.1.9' },
  ]

  commands = {
    puppet: 'bundle exec puppet --version',
    ruby:   'bundle exec ruby --version',
  }

  test_cases.each do |test_case|
    slug = (test_case[:envvar] == 'PDK_PE_VERSION') ? 'PE' : 'Puppet'

    step "Select #{slug} #{test_case[:version]}" do
      env = { test_case[:envvar] => test_case[:version] }

      gemspecs = on(workstation, "find #{install_dir(workstation)} -name 'puppet-#{test_case[:expected_puppet]}.*.gemspec'")
      puppet_versions = gemspecs.stdout.lines.map { |r| r[%r{puppet-([\d\.]+)(-.+?)?\.gemspec\Z}, 1] }
      expected_puppet_regex = puppet_versions.map { |r| Regexp.escape(r) }.join('|')

      on(workstation, "pushd #{module_name} && #{pdk_command(workstation, commands[:puppet], env)} && popd", accept_all_exit_codes: true) do |outcome|
        assert_match(%r{using puppet (#{expected_puppet_regex})}im, outcome.stderr,
                     "Should be using Puppet /(#{expected_puppet_regex})/. stderr was: #{outcome.stderr}")
      end

      on(workstation, "pushd #{module_name} && #{pdk_command(workstation, commands[:ruby], env)} && popd", accept_all_exit_codes: true) do |outcome|
        assert_match(%r{using ruby #{Regexp.escape(test_case[:expected_ruby])}}im, outcome.stderr,
                     "Should be using Ruby #{test_case[:expected_ruby]}. stderr was: #{outcome.stderr}")
      end
    end
  end
end
