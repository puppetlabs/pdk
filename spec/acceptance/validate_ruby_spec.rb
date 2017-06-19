require 'spec_helper_acceptance'

describe 'Validating a module' do
  context 'with a fresh module' do
    include_context 'in a new module', 'foo'

    describe command('pdk validate ruby') do
      its(:exit_status) do
        pending('current module template by default has like 109 offenses')
        is_expected.to eq 0
      end

      its(:stdout) do
        pending('correct output needs implementing')
        # TODO: fixup to correct message
        is_expected.to match(%r{Validating ruby style})
      end

      # its(:stdout) { is_expected.not_to match(%r{WARN|ERR}) }

      # use this weird regex to match for empty string to get proper diff output on failure
      # its(:stderr) { is_expected.to match(%r{\A\Z}) }
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
      its(:exit_status) do
        is_expected.not_to eq 0
      end

      its(:stdout) do
        pending('correct output needs implementing')
        # TODO: fixup to correct message
        is_expected.to match(%r{violation.rb sucks})
      end

      # its(:stdout) { is_expected.not_to match(%r{WARN|ERR}) }

      # use this weird regex to match for empty string to get proper diff output on failure
      # its(:stderr) { is_expected.to match(%r{\A\Z}) }
    end
  end
end
