test_name 'C100321 - Generate a module and validate it (i.e. ensure bundle install works)' do
  require 'pdk/pdk_helper.rb'

  module_name = 'c100321_module'

  teardown do
    on(workstation, "rm -rf #{module_name}") if module_name
  end

  step 'Create a module' do
    on(workstation, pdk_command(workstation, "new module #{module_name} --skip-interview"))
  end

  step 'Validate the module' do
    on(workstation, "cd #{module_name} && #{pdk_command(workstation, 'validate')}", accept_all_exit_codes: true) do |outcome|
      assert_equal(0, outcome.exit_code,
                   "Validate on a new module should return 0. stderr was: #{outcome.stderr}")
      on(workstation, "test -f #{module_name}/Gemfile.lock", accept_all_exit_codes: true) do |lock_check_outcome|
        assert_equal(0, lock_check_outcome.exit_code, 'pdk validate should have caused a Gemfile.lock file to be created')
      end
    end
  end
end
