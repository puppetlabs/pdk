require 'rexml/document'

RSpec::Matchers.define :have_junit_testcase do
  match do |xml_text|
    document = REXML::Document.new(xml_text)

    return false if document.root.nil?

    testcases = document.elements.to_a("/testsuites/testsuite[@name=\"#{@testsuite_name}\"]/testcase")

    if @expected_attributes
      testcases.select! do |testcase|
        @expected_attributes.all? do |attribute, expected_value|
          values_match?(expected_value, testcase.attribute(attribute).value)
        end
      end
    end

    case @status
    when :pass
      testcases.reject! do |testcase|
        testcase.has_elements?
      end
    when :skip
      testcases.reject! do |testcase|
        testcase.elements.to_a('skipped').empty?
      end
    when :fail
      testcases.reject! do |testcase|
        testcase.elements.to_a('failure').empty?
      end

      unless @failure_attributes.nil?
        testcases.select! do |testcase|
          @failure_attributes.all? do |attribute, expected_value|
            failure_element = testcase.elements.to_a('failure').first

            values_match?(expected_value, failure_element.attribute(attribute).value)
          end
        end
      end
    end

    !testcases.empty?
  end

  chain :with_attributes do |attributes|
    @expected_attributes = attributes
  end

  chain :in_testsuite do |testsuite_name|
    @testsuite_name = testsuite_name
  end

  chain :that_passed do
    @status = :pass
  end

  chain :that_was_skipped do
    @status = :skip
  end

  chain :that_failed do |attributes = nil|
    @status = :fail
    @failure_attributes = attributes
  end

  failure_message do |body|
    "expected to find a JUnit testcase#{chained_method_clause_sentences} in:\n#{body}"
  end

  failure_message_when_negated do |body|
    "expected not to find a JUnit testcase#{chained_method_clause_sentences} in:\n#{body}"
  end

  description do
    "have a JUnit testcase#{chained_method_clause_sentences}"
  end
end
