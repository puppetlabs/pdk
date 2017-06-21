require 'rexml/document'

RSpec::Matchers.define :have_xpath do |path|
  match do |xml_text|
    doc = REXML::Document.new(xml_text)
    nodes = doc.elements.to_a(path)

    if @expected_text
      nodes.select! do |node|
        values_match?(@expected_text, node.text)
      end
    end

    if @expected_attributes
      nodes.reject! do |node|
        retval = false

        @expected_attributes.each do |key, value|
          unless values_match?(value, node.attributes[key])
            retval = true
          end
        end

        retval
      end
    end

    !nodes.empty?
  end

  chain :with_text do |text|
    @expected_text = text
  end

  chain :with_attributes do |attributes|
    @expected_attributes = attributes
  end

  failure_message do |body|
    "expected to find an XML tag matching XPath '#{path}'#{chained_method_clause_sentences} in:\n#{body}"
  end

  failure_message_when_negated do |body|
    "expected not to find an XML tag matching XPath '#{path}'#{chained_method_clause_sentences} in:\n#{body}"
  end

  description do
    "have an XML tag matching XPath '#{path}'#{chained_method_clause_sentences}"
  end
end
