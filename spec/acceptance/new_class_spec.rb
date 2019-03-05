require 'spec_helper_acceptance'

describe 'pdk new class', module_command: true do
  shared_examples 'it creates a class' do |options|
    describe file(options[:manifest]) do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match(%r{class #{options[:name]} }) }
    end

    describe file(options[:spec]) do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match(%r{describe '#{options[:name]}' do}) }
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{0 failures}) }
      its(:stderr) { is_expected.not_to match(%r{no examples found}i) }
    end
  end

  context 'in a new module' do
    include_context 'in a new module', 'new_class'

    context 'when creating the main class' do
      describe command('pdk new class new_class') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stderr) { is_expected.to match(%r{Creating .* from template}) }
        its(:stderr) { is_expected.not_to match(%r{WARN|ERR}) }
        its(:stdout) { is_expected.to have_no_output }

        it_behaves_like 'it creates a class',
                        name: 'new_class',
                        manifest: File.join('manifests', 'init.pp'),
                        spec:     File.join('spec', 'classes', 'new_class_spec.rb')
      end
    end

    context 'when creating an ancillary class' do
      describe command('pdk new class new_class::bar') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stderr) { is_expected.to match(%r{Creating .* from template}) }
        its(:stderr) { is_expected.not_to match(%r{WARN|ERR}) }
        its(:stdout) { is_expected.to have_no_output }

        it_behaves_like 'it creates a class',
                        name:     'new_class::bar',
                        manifest: File.join('manifests', 'bar.pp'),
                        spec:     File.join('spec', 'classes', 'bar_spec.rb')
      end
    end

    context 'when creating a deeply nested class' do
      describe command('pdk new class new_class::bar::baz') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stderr) { is_expected.to match(%r{Creating .* from template}) }
        its(:stderr) { is_expected.not_to match(%r{WARN|ERR}) }
        its(:stdout) { is_expected.to have_no_output }

        it_behaves_like 'it creates a class',
                        name:     'new_class::bar::baz',
                        manifest: File.join('manifests', 'bar', 'baz.pp'),
                        spec:     File.join('spec', 'classes', 'bar', 'baz_spec.rb')
      end
    end
  end
end
