require 'spec_helper_acceptance'

describe 'pdk new defined_type', module_command: true do
  shared_examples 'it creates a defined type' do |name, created_files|
    describe command("pdk new defined_type #{name}") do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{creating .* from template}i) }
      its(:stderr) { is_expected.not_to match(%r{WARN|ERR}) }
      its(:stdout) { is_expected.to match(%r{\A\Z}) }

      describe file('manifests') do
        it { is_expected.to be_directory }
      end

      created_files.each do |filename, content|
        describe file(filename) do
          it { is_expected.to be_file }
          its(:content) { is_expected.to match(content) }
        end
      end

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{0 failures}) }
        its(:stderr) { is_expected.not_to match(%r{no examples found}i) }
      end
    end
  end

  context 'when run inside of a module' do
    include_context 'in a new module', 'new_define'

    context 'when creating a defined type with same name as the module' do
      it_behaves_like 'it creates a defined type', 'new_define',
                      File.join('manifests', 'init.pp')                  => %r{define new_define},
                      File.join('spec', 'defines', 'new_define_spec.rb') => %r{describe 'new_define' do}
    end

    context 'when creating an ancillary defined type' do
      it_behaves_like 'it creates a defined type', 'ancillary',
                      File.join('manifests', 'ancillary.pp')            => %r{define new_define::ancillary},
                      File.join('spec', 'defines', 'ancillary_spec.rb') => %r{describe 'new_define::ancillary' do}
    end

    context 'when creating a deeply nested defined type' do
      it_behaves_like 'it creates a defined type', 'new_define::foo::bar::baz',
                      File.join('manifests', 'foo', 'bar', 'baz.pp')            => %r{define new_define::foo::bar::baz},
                      File.join('spec', 'defines', 'foo', 'bar', 'baz_spec.rb') => %r{describe 'new_define::foo::bar::baz' do}
    end
  end
end
