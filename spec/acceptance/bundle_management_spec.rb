require 'spec_helper_acceptance'

describe 'Managing Gemfile dependencies' do
  include_context 'in a new module', 'bundle_management'

  context 'when there is an invalid Gemfile' do
    before(:all) do
      FileUtils.mv('Gemfile', 'Gemfile.old', force: true)
      File.open('Gemfile', 'w') do |f|
        f.puts 'not a gemfile'
      end
    end

    after(:all) do
      FileUtils.mv('Gemfile.old', 'Gemfile', force: true)
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.not_to eq 0 }
      its(:stderr) { is_expected.to match(%r{error parsing `gemfile`}i) }
    end
  end
end
