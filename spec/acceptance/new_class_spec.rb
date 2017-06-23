require 'spec_helper_acceptance'

describe 'pdk new class', module_command: true do
  context 'in a new module' do
    include_context 'in a new module', 'foo'

    context 'when creating the main class' do
      describe command('pdk new class foo') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{Creating .* from template}) }
        its(:stdout) { is_expected.not_to match(%r{WARN|ERR}) }
        # use this weird regex to match for empty string to get proper diff output on failure
        its(:stderr) { is_expected.to match(%r{\A\Z}) }
      end

      describe file('manifests') do
        it { is_expected.to be_directory }
      end

      describe file('manifests/init.pp') do
        it { is_expected.to be_file }
        its(:content) do
          is_expected.to match(%r{class foo })
        end
      end

      describe file('spec/classes/foo_spec.rb') do
        it { is_expected.to be_file }
        its(:content) do
          is_expected.to match(%r{foo})
        end
      end
    end

    context 'when creating an ancillary class' do
      describe command('pdk new class foo::bar') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{Creating .* from template}) }
        its(:stdout) { is_expected.not_to match(%r{WARN|ERR}) }
        # use this weird regex to match for empty string to get proper diff output on failure
        its(:stderr) { is_expected.to match(%r{\A\Z}) }
      end

      describe file('manifests') do
        it { is_expected.to be_directory }
      end

      describe file('manifests/bar.pp') do
        it { is_expected.to be_file }
        its(:content) do
          is_expected.to match(%r{class foo::bar})
        end
      end

      describe file('spec/classes/bar_spec.rb') do
        it { is_expected.to be_file }
        its(:content) do
          is_expected.to match(%r{foo::bar})
        end
      end
    end

    context 'when creating a deeply nested class' do
      describe command('pdk new class foo::bar::baz') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{Creating .* from template}) }
        its(:stdout) { is_expected.not_to match(%r{WARN|ERR}) }
        # use this weird regex to match for empty string to get proper diff output on failure
        its(:stderr) { is_expected.to match(%r{\A\Z}) }
      end

      describe file('manifests') do
        it { is_expected.to be_directory }
      end

      describe file('manifests/bar/baz.pp') do
        it { is_expected.to be_file }
        its(:content) do
          is_expected.to match(%r{class foo::bar::baz})
        end
      end

      describe file('spec/classes/bar/baz_spec.rb') do
        it { is_expected.to be_file }
        its(:content) do
          is_expected.to match(%r{foo::bar::baz})
        end
      end
    end
  end
end
