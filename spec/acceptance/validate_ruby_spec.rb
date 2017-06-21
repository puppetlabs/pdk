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

    spec_violation_rb = File.join('spec', 'violation.rb')

    before(:all) do
      File.open(spec_violation_rb, 'w') do |f|
        f.puts 'f = %(x y z)'
      end
    end

    describe command('pdk validate ruby') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stdout) { is_expected.to match(%r{#{Regexp.escape(spec_violation_rb)}.*useless assignment}i) }
      its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
    end

    # Make use of the offending file above to test that target selection works
    # as expected.
    context 'when validating specific files' do
      describe command("pdk validate ruby #{File.join('spec', 'spec_helper.rb')}") do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{\A\Z}) }
        its(:stderr) { is_expected.to match(%r{checking ruby code style}i) }
      end
    end

    context 'when validating specific directories' do
      another_violation_rb = File.join('lib', 'puppet', 'another_violation.rb')

      before(:all) do
        FileUtils.mkdir_p(File.dirname(another_violation_rb))
        File.open(another_violation_rb, 'w') do |f|
          f.puts "puts {:foo => 'bar'}.inspect"
        end
      end

      describe command('pdk validate ruby lib') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stdout) { is_expected.to match(%r{#{Regexp.escape(another_violation_rb)}}) }
        its(:stdout) { is_expected.not_to match(%r{#{Regexp.escape(spec_violation_rb)}}) }
        its(:stderr) { is_expected.to match(%r{checking ruby code style}i) }
      end
    end
  end
end
