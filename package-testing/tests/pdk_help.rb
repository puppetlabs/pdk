# frozen_string_literal: true

test_name 'C100022 - pdk --help' do
  require 'pdk/pdk_helper.rb'

  on(workstation, pdk_command(workstation, '--help'), accept_all_exit_codes: true) do |outcome|
    assert_equal(0, outcome.exit_code, "pdk --help should exit with 0. stderr: #{outcome.stderr}")
    assert_match(%r{NAME.*USAGE.*DESCRIPTION.*COMMANDS.*OPTIONS}m, outcome.stdout, 'stdout should contain basic help information for pdk')
  end
end
