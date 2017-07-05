require 'spec_helper_acceptance'

describe 'Running metadata validation' do
  let(:spinner_text) { %r{checking metadata}i }

  context 'with a fresh module' do
    include_context 'in a new module', 'metadata_validation_module'

    describe command('pdk validate metadata') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(%r{\A\Z}) }
      its(:stderr) { is_expected.to match(spinner_text) }
    end

    describe command('pdk validate metadata --format junit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(spinner_text) }
      it_behaves_like :it_generates_valid_junit_xml

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="metadata-json-lint"]').with_attributes(
          'failures' => '0',
          'tests'    => '1',
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="metadata-json-lint"]/testcase').with_attributes(
          'classname' => 'metadata-json-lint',
          'name'      => 'metadata.json',
        )
      end
    end
  end

  context 'with a metadata violation' do
    include_context 'in a new module', 'metadata_violation_module'

    before(:all) do
      metadata = JSON.parse(File.read('metadata.json'))
      metadata['dependencies'].first['version_requirement'] = '>= 1.0.0'
      File.open('metadata.json', 'w') do |f|
        f.puts metadata.to_json
      end
    end

    describe command('pdk validate metadata') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stdout) { is_expected.to match(%r{^metadata\.json:.+warning.+open ended dependency}) }
      its(:stderr) { is_expected.to match(spinner_text) }
    end

    describe command('pdk validate metadata --format junit') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stderr) { is_expected.to match(spinner_text) }
      it_behaves_like :it_generates_valid_junit_xml

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="metadata-json-lint"]').with_attributes(
          'failures' => '1',
          'tests'    => '1',
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="metadata-json-lint"]/testcase').with_attributes(
          'classname' => 'metadata-json-lint.dependencies',
          'name'      => 'metadata.json',
        )
      end
    end
  end

  context 'when validating a specific file' do
    include_context 'in a new module', 'metadata_specific_module'

    before(:all) do
      FileUtils.cp('metadata.json', 'broken.json')
      broken_metadata = JSON.parse(File.read('broken.json'))
      broken_metadata['dependencies'].first['version_requirement'] = '>= 1.0.0'
      File.open('broken.json', 'w') do |f|
        f.puts broken_metadata.to_json
      end
    end

    describe command('pdk validate metadata --format junit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(spinner_text) }

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
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stderr) { is_expected.to match(spinner_text) }

      its(:stdout) do
        is_expected.not_to have_xpath('/testsuites/testsuite[@name="metadata-json-lint"]/testcase').with_attributes(
          'name' => 'metadata.json',
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="metadata-json-lint"]/testcase').with_attributes(
          'classname' => 'metadata-json-lint.dependencies',
          'name'      => 'broken.json',
        )
      end
    end

    describe command('pdk validate metadata --format junit *.json') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stderr) { is_expected.to match(spinner_text) }

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="metadata-json-lint"]/testcase').with_attributes(
          'classname' => 'metadata-json-lint',
          'name'      => 'metadata.json',
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="metadata-json-lint"]/testcase').with_attributes(
          'classname' => 'metadata-json-lint.dependencies',
          'name'      => 'broken.json',
        )
      end
    end
  end
end
