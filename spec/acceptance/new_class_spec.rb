require 'spec_helper_acceptance'

describe 'pdk new class', module_command: true do
  context 'in a new module' do
    include_context 'in a new module', 'new_class'

    context 'when creating the main class' do
      describe command('pdk new class new_class') do
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
          is_expected.to match(%r{class new_class })
        end
      end

      describe file('spec/classes/new_class_spec.rb') do
        it { is_expected.to be_file }
        its(:content) do
          is_expected.to match(%r{new_class})
        end
      end
    end

    context 'when creating an ancillary class' do
      describe command('pdk new class new_class::bar') do
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
          is_expected.to match(%r{class new_class::bar})
        end
      end

      describe file('spec/classes/bar_spec.rb') do
        it { is_expected.to be_file }
        its(:content) do
          is_expected.to match(%r{new_class::bar})
        end
      end
    end

    context 'when creating a deeply nested class' do
      describe command('pdk new class new_class::bar::baz') do
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
          is_expected.to match(%r{class new_class::bar::baz})
        end
      end

      describe file('spec/classes/bar/baz_spec.rb') do
        it { is_expected.to be_file }
        its(:content) do
          is_expected.to match(%r{new_class::bar::baz})
        end
      end

      context 'when running the generated spec tests' do
        describe command('pdk test unit') do
          its(:exit_status) { is_expected.to eq 0 }
          its(:stderr) { is_expected.to match(%r{0 failures}) }
          its(:stderr) { is_expected.not_to match(%r{No examples found}) }
        end
      end
    end
  end
end
