require 'spec_helper_acceptance'

describe 'pdk validate metadata', module_command: true do
  let(:metadata_syntax_spinner) { %r{checking metadata syntax}i }
  let(:module_style_spinner) { %r{checking module metadata style}i }
  let(:task_style_spinner) { %r{checking task metadata style}i }

  def broken_metadata
    JSON.parse(File.read('metadata.bak')).tap do |metadata|
      metadata['dependencies'] = [
        { 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 4.0.0' },
      ]
    end
  end

  include_context 'with a fake TTY'

  context 'when run inside of a module' do
    include_context 'in a new module', 'metadata_validation'

    before(:all) do
      FileUtils.cp('metadata.json', 'metadata.bak')
    end

    context 'with a metadata violation' do
      before(:all) do
        File.open('metadata.json', 'w') { |f| f.puts broken_metadata.to_json }
      end

      after(:all) do
        FileUtils.cp('metadata.bak', 'metadata.json')
      end

      describe command('pdk validate metadata --format text:stdout --format junit:report.xml') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stdout) { is_expected.to match(%r{\(warning\): metadata-json-lint:.+open ended dependency}i) }
        its(:stderr) { is_expected.to match(metadata_syntax_spinner) }

        describe file('report.xml') do
          its(:content) { is_expected.to contain_valid_junit_xml }

          its(:content) do
            is_expected.to have_junit_testsuite('metadata-json-lint').with_attributes(
              'failures' => eq(1),
              'tests' => eq(1),
            )
          end

          its(:content) do
            is_expected.to have_junit_testcase.in_testsuite('metadata-json-lint').with_attributes(
              'classname' => 'metadata-json-lint.dependencies',
              'name' => 'metadata.json',
            ).that_failed
          end
        end
      end
    end

    context 'when attempting to validate a specific invalid file' do
      before(:all) do
        File.open('broken.json', 'w') { |f| f.puts broken_metadata.to_json }
      end

      after(:all) do
        FileUtils.rm('broken.json')
      end

      describe command('pdk validate metadata --format junit') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(metadata_syntax_spinner) }

        its(:stdout) do
          is_expected.to have_xpath('/testsuites/testsuite[@name="metadata-json-lint"]/testcase').with_attributes(
            'name' => 'metadata.json',
          )
        end

        its(:stdout) do
          is_expected.not_to have_xpath('/testsuites/testsuite[@name="metadata-json-lint"]/testcase').with_attributes(
            'name' => 'broken.json',
          )
        end
      end

      describe command('pdk validate metadata --format junit broken.json') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(metadata_syntax_spinner) }

        its(:stdout) do
          is_expected.to have_xpath('/testsuites/testsuite[@name="metadata-json-lint"]').with_attributes(
            'tests' => '1',
            'skipped' => '1',
          )
        end

        its(:stdout) do
          is_expected.to have_xpath('/testsuites/testsuite[@name="metadata-json-lint"]/testcase').with_attributes(
            'name' => 'broken.json',
          )
        end
      end

      context 'and metadata.json has errors' do
        before(:all) do
          File.open('metadata.json', 'w') { |f| f.puts broken_metadata.to_json }
        end

        after(:all) do
          FileUtils.cp('metadata.bak', 'metadata.json')
        end

        describe command('pdk validate metadata --format junit broken.json') do
          its(:exit_status) { is_expected.to eq(0) }
          its(:stderr) { is_expected.to match(metadata_syntax_spinner) }

          its(:stdout) do
            is_expected.to have_junit_testsuite('metadata-json-lint').with_attributes(
              'skipped' => eq(1),
              'tests' => eq(1),
            )
          end

          its(:stdout) do
            is_expected.to have_xpath('/testsuites/testsuite[@name="metadata-json-lint"]/testcase').with_attributes(
              'name' => 'broken.json',
            )
          end
        end
      end
    end
  end
end
