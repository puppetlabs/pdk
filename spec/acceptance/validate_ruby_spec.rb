require 'spec_helper_acceptance'

describe 'Running ruby validation' do
  context 'with a fresh module' do
    include_context 'in a new module', 'foo'

    describe command('pdk validate ruby') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(%r{\A\Z}) }
      its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
    end
  end

  context 'with a style violation' do
    include_context 'in a new module', 'foo'

    before(:all) do
      File.open('spec/violation.rb', 'w') do |f|
        f.puts 'f = %(x y z)'
      end
    end

    describe command('pdk validate ruby') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stdout) { is_expected.to match(%r{\Aspec/violation\.rb.*useless assignment}i) }
      its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
    end
  end
end
