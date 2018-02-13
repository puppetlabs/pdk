RSpec::Matchers.define(:exit_with_status) do |expected_status|
  supports_block_expectations

  match do |block|
    expectation_passed = false

    begin
      block.call
    rescue SystemExit => e
      expectation_passed = values_match?(expected_status, e.status)
    rescue
      nil
    end

    expectation_passed
  end
end
