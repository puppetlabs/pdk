require 'spec_helper_acceptance'

describe 'pdk new defined_type', module_command: true do
  shared_examples 'it creates a defined type' do |name|
    describe command("pdk new defined_type #{name}") do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{creating .* from template}i) }
      its(:stderr) { is_expected.not_to match(%r{WARN|ERR}) }
      its(:stdout) { is_expected.to match(%r{\A\Z}) }
    end

    describe file('manifests') do
      it { is_expected.to be_directory }
    end

    context 'when running the generated spec tests' do
      describe command('pdk test unit') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{0 failures}) }
        its(:stderr) { is_expected.not_to match(%r{no examples found}i) }
      end
    end
  end

  context 'in a fresh module' do
    include_context 'in a new module', 'new_define'

    context 'when creating a defined type with same name as the module' do
      it_behaves_like 'it creates a defined type', 'new_define'

      describe file('manifests/init.pp') do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{define new_define}) }
      end

      describe file('spec/defines/new_define_spec.rb') do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{describe 'new_define' do}) }
      end
    end

    context 'when creating an ancillary defined type' do
      it_behaves_like 'it creates a defined type', 'ancillary'

      describe file('manifests/ancillary.pp') do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{define new_define::ancillary}) }
      end

      describe file('spec/defines/ancillary_spec.rb') do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{describe 'new_define::ancillary' do}) }
      end
    end

    context 'when creating a deeply nested defined type' do
      it_behaves_like 'it creates a defined type', 'new_define::foo::bar::baz'

      describe file('manifests/foo/bar/baz.pp') do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{define new_define::foo::bar::baz}) }
      end

      describe file('spec/defines/foo/bar/baz_spec.rb') do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{describe 'new_define::foo::bar::baz' do}) }
      end
    end
  end
end
