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
    { envvar: 'PDK_PUPPET_VERSION', version: '5.5.0', expected_puppet: '5.3.2', expected_ruby: '2.4.3' },
    { envvar: 'PDK_PUPPET_VERSION', version: '4.10.1', expected_puppet: '4.10.1', expected_ruby: '2.1.9' },
    { envvar: 'PDK_PE_VERSION', version: '2017.3.1', expected_puppet: '5.3.2', expected_ruby: '2.4.3' },
    { envvar: 'PDK_PE_VERSION', version: '2017.2.1', expected_puppet: '4.10.1', expected_ruby: '2.1.9' },
  ]

  commands = {
    puppet: 'bundle exec puppet --version',
    ruby:   'bundle exec ruby --version',
  }

  test_cases.each do |test_case|
    slug = (test_case[:envvar] == 'PDK_PE_VERSION') ? 'PE' : 'Puppet'

    step "Select #{slug} #{test_case[:version]}" do
      on_opts = {
        accept_all_exit_codes: true,
        environment:           {
          test_case[:envvar] => test_case[:version],
        },
      }

      on(workstation, "cd #{module_name} && #{pdk_command(workstation, commands[:puppet])}", on_opts) do |outcome|
        assert_match(%r{^#{Regexp.escape(test_case[:expected_puppet])}$}m, outcome.stderr,
                     "Should be using Puppet #{test_case[:expected_puppet]}. stderr was: #{outcome.stderr}")
      end

      on(workstation, "cd #{module_name} && #{pdk_command(workstation, commands[:ruby])}", on_opts) do |outcome|
        assert_match(%r{^ruby #{Regexp.escape(test_case[:expected_ruby])}}im, outcome.stderr,
                     "Should be using Ruby #{test_case[:expected_ruby]}. stderr was: #{outcome.stderr}")
      end
    end
  end
end
