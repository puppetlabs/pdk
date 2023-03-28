require 'pdk/validate/validator'

# A mock validator which doesn't raise an error
class MockSuccessValidator < PDK::Validate::Validator
  def name
    'mocksuccess'
  end

  def invoke(report)
    report.add_event(
      file: 'pass.txt',
      source: name,
      state: :passed,
      severity: 'ok',
    )

    0
  end
end

# A mock validator which is not valid in any context
class MockNoContextValidator < PDK::Validate::Validator
  def name
    'mocknocontext'
  end

  def valid_in_context?
    false
  end

  def invoke(_report)
    raise 'The MockNoContextValidator should never be invoked'
  end
end

# A mock validator which has a single failure
class MockFailedValidator < PDK::Validate::Validator
  def name
    'mockfailed'
  end

  def invoke(report)
    report.add_event(
      file: 'fail.txt',
      source: name,
      state: :failure,
      severity: 'error',
      message: 'Mock Failure',
    )

    1
  end
end

# A mock validator which has a single failure
class MockAnotherFailedValidator < PDK::Validate::Validator
  def name
    'anothermockfailed'
  end

  def invoke(report)
    report.add_event(
      file: 'another_fail.txt',
      source: name,
      state: :failure,
      severity: 'error',
      message: 'Another Mock Failure',
    )

    2
  end
end

RSpec::Matchers.define :have_number_of_events do |state, expected_count|
  def get_event_count(report, state)
    count = 0
    report.events.each do |_source, events|
      count += events.count { |event| event.state == state }
    end

    count
  end

  match do |report|
    get_event_count(report, state) == expected_count
  end
end

RSpec.shared_examples 'a successful result' do |num_success_reports|
  it 'returns a zero exit code' do
    exit_code, = invokation_result
    expect(exit_code).to eq(0)
  end

  it "has #{num_success_reports} passed report event/s" do
    _, report = invokation_result
    expect(report).to have_number_of_events(:passed, num_success_reports)
  end

  it 'has no failed report event/s' do
    _, report = invokation_result
    expect(report).to have_number_of_events(:failure, 0)
  end
end

RSpec.shared_examples 'a failed result' do |num_success_reports, num_failed_reports|
  it 'returns a non-zero exit code' do
    exit_code, = invokation_result
    expect(exit_code).not_to eq(0)
  end

  it "has #{num_success_reports} passed report event/s" do
    _, report = invokation_result
    expect(report).to have_number_of_events(:passed, num_success_reports)
  end

  it "has #{num_failed_reports} failed report event/s" do
    _, report = invokation_result
    expect(report).to have_number_of_events(:failure, num_failed_reports)
  end
end
