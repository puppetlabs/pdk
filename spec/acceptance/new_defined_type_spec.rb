require 'spec_helper_acceptance'

describe 'pdk new defined_type', module_command: true do
  shared_examples 'it creates a defined type' do |options|
    describe file(options[:manifest]) do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match(%r{define #{options[:name]}}) }
    end

    describe file(options[:spec]) do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match(%r{describe '#{options[:name]}' do}) }
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(%r{0 failures}) }
      its(:stdout) { is_expected.not_to match(%r{no examples found}i) }
    end
  end

  context 'when run inside of a module' do
    include_context 'in a new module', 'new_define'

    context 'when creating a defined type with same name as the module' do
      describe command('pdk new defined_type new_define') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{Files added}) }
        its(:stdout) { is_expected.to match(%r{#{File.join('manifests', 'init.pp')}}) }
        its(:stdout) { is_expected.to match(%r{#{File.join('spec', 'defines', 'new_define_spec.rb')}}) }
        its(:stderr) { is_expected.to have_no_output }

        it_behaves_like 'it creates a defined type',
                        name:     'new_define',
                        manifest: File.join('manifests', 'init.pp'),
                        spec:     File.join('spec', 'defines', 'new_define_spec.rb')
      end
    end

    context 'when creating an ancillary defined type' do
      describe command('pdk new defined_type ancillary') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{Files added}) }
        its(:stdout) { is_expected.to match(%r{#{File.join('manifests', 'ancillary.pp')}}) }
        its(:stdout) { is_expected.to match(%r{#{File.join('spec', 'defines', 'ancillary_spec.rb')}}) }
        its(:stderr) { is_expected.to have_no_output }

        it_behaves_like 'it creates a defined type',
                        name:     'new_define::ancillary',
                        manifest: File.join('manifests', 'ancillary.pp'),
                        spec:     File.join('spec', 'defines', 'ancillary_spec.rb')
      end
    end

    context 'when creating a deeply nested defined type' do
      describe command('pdk new defined_type new_define::foo::bar::baz') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{Files added}) }
        its(:stdout) { is_expected.to match(%r{#{File.join('manifests', 'foo', 'bar', 'baz.pp')}}) }
        its(:stdout) { is_expected.to match(%r{#{File.join('spec', 'defines', 'foo', 'bar', 'baz_spec.rb')}}) }
        its(:stderr) { is_expected.to have_no_output }

        it_behaves_like 'it creates a defined type',
                        name:     'new_define::foo::bar::baz',
                        manifest: File.join('manifests', 'foo', 'bar', 'baz.pp'),
                        spec:     File.join('spec', 'defines', 'foo', 'bar', 'baz_spec.rb')
      end
    end
  end
end
