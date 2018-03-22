# frozen_string_literal: true

require 'rexml/document'

RSpec::Matchers.define :have_junit_testsuite do |testsuite_name|
  match do |xml_text|
    document = REXML::Document.new(xml_text)

    return false if document.root.nil?

    testsuites = document.elements.to_a("/testsuites/testsuite[@name=\"#{testsuite_name}\"]")

    if @expected_attributes
      testsuites.select! do |testsuite|
        @expected_attributes.all? do |attribute, expected_value|
          actual_value = case attribute
                         when 'tests', 'failures', 'errors', 'skipped'
                           testsuite.attribute(attribute).value.to_i
                         else
                           testsuite.attribute(attribute).value
                         end
          values_match?(expected_value, actual_value)
        end
      end
    end

    !testsuites.empty?
  end

  chain :with_attributes do |attributes|
    @expected_attributes = attributes
  end

  failure_message do |body|
    "expected to find a JUnit testsuite named '#{testsuite_name}'#{chained_method_clause_sentences} in:\n#{body}"
  end

  failure_message_when_negated do |body|
    "expected not to find a JUnit testsuite named '#{testsuite_name}'#{chained_method_clause_sentences} in:\n#{body}"
  end

  description do
    "have a JUnit testsuite named '#{testsuite_name}'#{chained_method_clause_sentences}"
  end
end
