require 'spec_helper'
require 'pdk/report'

describe PDK::Report do
  %w[junit text].each do |report_format|
    it "can format the report as #{report_format}" do
      expect(described_class.formats).to include(report_format)
      expect(subject).to respond_to("write_#{report_format}")
    end
  end

  it 'defaults to the text format' do
    expect(described_class.default_format).to eq(:write_text)
  end

  it 'defaults to writing to stdout' do
    expect(described_class.default_target).to eq($stdout)
  end

  it 'has no events in the report by default' do
    expect(subject).to have_attributes(events: {})
  end

  context 'when adding events to the report' do
    subject(:report) do
      r = described_class.new
      events.each { |event| r.add_event(event) }
      r
    end

    let(:events) do
      [
        { source: 'puppet-lint', state: :failure, file: 'testfile.pp' },
        { source: 'rubocop', state: :passed, file: 'testfile.rb' },
      ]
    end

    it 'stores the events in the report by source' do
      expect(report).to have_attributes(
        events: {
          'puppet-lint' => [instance_of(PDK::Report::Event)],
          'rubocop' => [instance_of(PDK::Report::Event)],
        },
      )
    end

    context 'and rendering the report as text' do
      after(:each) do
        report.write_text('target')
      end

      it 'does not include passing events' do
        expect(PDK::Util::Filesystem).to receive(:write_file)
          .with(anything, satisfy { |content| content.split("\n").length == 1 })
      end

      it 'does include non-passing events' do
        expected_report = report.events.map(&:last).flatten.reject(&:pass?).map(&:to_text).join("\n")
        expect(PDK::Util::Filesystem).to receive(:write_file).with(anything, expected_report)
      end

      context 'and the report contains an rspec-puppet coverage report' do
        let(:events) do
          [
            {
              source: 'rspec',
              state: :passed,
              file: "#{PDK::Util::Filesystem.expand_path(Dir.pwd)}/private/cache/ruby/lib/rspec-puppet/coverage.rb",
              message: 'coverage report text',
            },
            {
              source: 'rspec',
              state: :failure,
              file: 'spec/classes/foo_spec.rb',
              message: 'some failure happened',
            },
          ]
        end

        before(:each) do
          allow(PDK::Util).to receive(:module_root).and_return(EMPTY_MODULE_ROOT)
        end

        it 'prints the coverage report last' do
          expect(PDK::Util::Filesystem).to receive(:write_file)
            .with(anything, satisfy { |content| content.split("\n").last == 'coverage report text' })
        end
      end
    end

    context 'and rendering the report as JUnit XML' do
      after(:each) do
        report.write_junit('target')
      end

      it 'produces parsable XML' do
        is_xml = satisfy do |content|
          REXML::Document.new(content).is_a?(REXML::Document)
        end

        expect(PDK::Util::Filesystem).to receive(:write_file)
          .with(anything, is_xml)
      end

      it 'creates a testsuite for each event source' do
        has_testsuites = satisfy do |content|
          doc = REXML::Document.new(content)
          testsuites = doc.elements.to_a('/testsuites/testsuite')
          testsuites.length == 2
        end

        expect(PDK::Util::Filesystem).to receive(:write_file)
          .with(anything, has_testsuites)
      end

      it 'includes passing events in the testsuite' do
        has_passing_events = satisfy do |content|
          doc = REXML::Document.new(content)
          rubocop_suite = doc.elements['/testsuites/testsuite[@name="rubocop"]']

          rubocop_suite.attributes['tests'] == '1' &&
            rubocop_suite.attributes['failures'] == '0' &&
            rubocop_suite.elements.to_a('testcase').length == 1 &&
            rubocop_suite.elements['testcase'].to_s == report.events['rubocop'].first.to_junit.to_s
        end

        expect(PDK::Util::Filesystem).to receive(:write_file)
          .with(anything, has_passing_events)
      end

      it 'includes non-passing events in the testsuite' do
        has_failing_events = satisfy do |content|
          doc = REXML::Document.new(content)
          puppet_lint_suite = doc.elements['/testsuites/testsuite[@name="puppet-lint"]']
          # Strip whitespace out of element from document as it formats
          # differently to an element not part of a document.
          testcase = puppet_lint_suite.elements['testcase'].to_s.gsub(%r{\s*\n\s*}, '')

          puppet_lint_suite.attributes['tests'] == '1' &&
            puppet_lint_suite.attributes['failures'] == '1' &&
            puppet_lint_suite.elements.to_a('testcase').length == 1 &&
            testcase == report.events['puppet-lint'].first.to_junit.to_s
        end

        expect(PDK::Util::Filesystem).to receive(:write_file)
          .with(anything, has_failing_events)
      end
    end
  end
end
