RSpec.shared_examples_for :it_generates_valid_junit_xml do
  its(:stdout) do
    xsd = File.join(RSpec.configuration.fixtures_path, 'JUnit.xsd')
    is_expected.to pass_validation(xsd)
  end
end
