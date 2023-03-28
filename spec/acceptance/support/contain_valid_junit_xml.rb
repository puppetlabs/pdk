require 'rspec/xsd'

module RSpec
  module XSD
    class Matcher
      attr_reader :errors
    end
  end
end

RSpec::Matchers.define :contain_valid_junit_xml do
  match do |text|
    xsd = File.join(RSpec.configuration.fixtures_path, 'JUnit.xsd')
    @matcher = RSpec::XSD::Matcher.new(xsd, nil)
    @matcher.matches?(text)
  end

  description do
    'contain valid JUnit XML'
  end

  failure_message do
    "expected that it would contain valid JUnit XML\r\n\r\n#{@matcher.errors.join("\r\n")}"
  end

  failure_message_when_negated do
    'expected that it would not contain valid JUnit XML'
  end
end
