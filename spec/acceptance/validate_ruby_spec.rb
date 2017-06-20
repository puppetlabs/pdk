require 'spec_helper_acceptance'

describe 'Validating a module' do
  context 'with a fresh module' do
    include_context 'in a new module', 'foo'

    describe command('pdk validate ruby') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(%r{2 files inspected, no offenses detected}) }
    end
  end

  context 'with a style violation' do
    include_context 'in a new module', 'foo'

    before(:all) do
      File.open('spec/violation.rb', 'w') do |f|
        f.puts <<EOF
f = %(x y z)
EOF
      end
    end

    describe command('pdk validate ruby') do
      its(:exit_status) { is_expected.not_to eq 0 }
      its(:stdout) { is_expected.to match(%r{3 files inspected, 1 offense detected}) }
    end
  end
end
