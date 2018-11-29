require 'spec_helper_acceptance'

describe 'pdk bundle' do
  context 'in a new module' do
    include_context 'in a new module', 'bundle'

    before(:all) do
      File.open(File.join('manifests', 'init.pp'), 'w') do |f|
        f.puts '$foo = "bar"'
      end
    end

    describe command('pdk bundle env') do
      its(:exit_status) { is_expected.to eq 0 }
      # use this weird regex to match for empty string to get proper diff output on failure
      its(:stdout) { is_expected.to match(%r{\A\Z}) }
      its(:stderr) { is_expected.to match(%r{## Environment}) }
    end

    context 'when running in a subdirectory of the module root' do
      before(:all) do
        Dir.chdir('manifests')
      end

      after(:all) do
        Dir.chdir('..')
      end

      describe command('pdk bundle exec puppet-lint init.pp') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{\A\Z}) }
        its(:stderr) { is_expected.to match(%r{double quoted string}im) }
      end
    end
  end
end
