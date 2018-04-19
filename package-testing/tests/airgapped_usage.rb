test_name 'Basic usage in an air-gapped environment (no network access to rubygems.org)' do
  require 'pdk/pdk_helper.rb'

  module_name = 'airgapped_module'
  hosts_file = (workstation.platform =~ %r{windows}) ? '/cygdrive/c/Windows/System32/Drivers/etc/hosts' : '/etc/hosts'

  teardown do
    on(workstation, "rm -rf #{module_name}") if module_name
    on(workstation, "cp #{hosts_file}.bak #{hosts_file}", accept_all_exit_codes: true)
  end

  step 'Disable access to rubygems.org' do
    on(workstation, "cp #{hosts_file} #{hosts_file}.bak", accept_all_exit_codes: true)
    on(workstation, "echo \"127.0.0.1 rubygems.org\" >> #{hosts_file}", accept_all_exit_codes: true)
  end

  step 'Create module' do
    on(workstation, pdk_command(workstation, "new module #{module_name} --skip-interview")) do
      on(workstation, %(cat #{module_name}/metadata.json | egrep '"template-url":'), accept_all_exit_codes: true) do |template_result|
        assert_match(%r{"file://.*pdk-templates\.git",?$}, template_result.stdout.strip, "New module's metadata should refer to vendored pdk-templates repo")
      end
    end
  end

  step 'Validate the module' do
    on(workstation, "cd #{module_name} && #{pdk_command(workstation, 'validate --debug')}", accept_all_exit_codes: true) do |outcome|
      assert_equal(0, outcome.exit_code,
                   "Validate on a new module should return 0. stderr was: #{outcome.stderr}")

      on(workstation, "test -f #{module_name}/Gemfile.lock", accept_all_exit_codes: true) do |lock_check_outcome|
        assert_equal(0, lock_check_outcome.exit_code, 'pdk validate should have caused a Gemfile.lock file to be created')
      end

      on(workstation, "diff #{install_dir(workstation)}/share/cache/Gemfile.lock #{module_name}/Gemfile.lock", accept_all_exit_codes: true) do |gemfile_cmp|
        assert_equal(0, gemfile_cmp.exit_code, "newly created Gemfile.lock should match vendored Gemfile.lock but it had differences: #{gemfile_cmp.stdout}")
      end
    end
  end
end
