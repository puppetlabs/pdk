require 'spec_helper'
require 'tmpdir'
require 'stringio'

describe PDK::Report do
  %w[junit text].each do |report_format|
    it "can format the report as #{report_format}" do
      expect(described_class.formats).to include(report_format)
      is_expected.to respond_to("write_#{report_format}")
    end
  end

  it 'defaults to the text format' do
    expect(described_class.default_format).to eq(:write_text)
  end

  it 'defaults to writing to stdout' do
    expect(described_class.default_target).to eq($stdout)
  end

  it 'has no events in the report by default' do
    is_expected.to have_attributes(events: {})
  end

  context 'when adding events to the report' do
    subject(:report) do
      r = described_class.new
      r.add_event(source: 'puppet-lint', state: :failure, file: 'testfile.pp')
      r.add_event(source: 'rubocop', state: :passed, file: 'testfile.rb')
      r
    end

    it 'stores the events in the report by source' do
      expect(report).to have_attributes(
        events: {
          'puppet-lint' => [instance_of(PDK::Report::Event)],
          'rubocop'     => [instance_of(PDK::Report::Event)],
        },
      )
    end

    context 'and rendering the report as text' do
      subject(:text_report) do
        io = StringIO.new
        report.write_text(io)
        io.rewind
        io.read
      end

      it 'does not include passing events' do
        expect(text_report.split("\n").length).to eq(1)
      end

      it 'does include non-passing events' do
        expected_report = report.events.map(&:last).flatten.reject(&:pass?).map(&:to_text).join("\n")
        expect(text_report.strip).to eq(expected_report)
      end

      it 'finishes with a trailing newline' do
        expect(text_report[-1]).to eq("\n")
      end
    end

    context 'and rendering the report as JUnit XML' do
      subject(:junit_report) do
        io = StringIO.new
        report.write_junit(io)
        io.rewind
        REXML::Document.new(io)
      end

      it 'produces parsable XML' do
        expect(junit_report).to be_a(REXML::Document)
      end

      it 'creates a testsuite for each event source' do
        testsuites = junit_report.elements.to_a('/testsuites/testsuite')
        expect(testsuites.length).to eq(2)
      end

      it 'includes passing events in the testsuite' do
        rubocop_suite = junit_report.elements['/testsuites/testsuite[@name="rubocop"]']
        expect(rubocop_suite.attributes['tests']).to eq('1')
        expect(rubocop_suite.attributes['failures']).to eq('0')
        expect(rubocop_suite.elements.to_a('testcase').length).to eq(1)
        expect(rubocop_suite.elements['testcase'].to_s).to eq(report.events['rubocop'].first.to_junit.to_s)
      end

      it 'includes non-passing events in the testsuite' do
        puppet_lint_suite = junit_report.elements['/testsuites/testsuite[@name="puppet-lint"]']
        expect(puppet_lint_suite.attributes['tests']).to eq('1')
        expect(puppet_lint_suite.attributes['failures']).to eq('1')
        expect(puppet_lint_suite.elements.to_a('testcase').length).to eq(1)

        # Strip whitespace out of element from document as it formats
        # differently to an element not part of a document.
        testcase = puppet_lint_suite.elements['testcase'].to_s.gsub(%r{\s*\n\s*}, '')
        expect(testcase).to eq(report.events['puppet-lint'].first.to_junit.to_s)
      end
    end
  end
end
