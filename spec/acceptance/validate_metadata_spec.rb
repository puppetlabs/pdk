require 'spec_helper_acceptance'

describe 'Running metadata validation' do
  let(:spinner_text) { %r{checking metadata\.json}i }

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
        is_expected.to have_junit_testsuite('metadata-json-lint').with_attributes(
          'failures' => eq(0),
          'tests'    => eq(1),
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
    include_context 'in a new module', 'foo'

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
        is_expected.to have_junit_testsuite('metadata-json-lint').with_attributes(
          'failures' => eq(1),
          'tests'    => eq(1),
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
end
