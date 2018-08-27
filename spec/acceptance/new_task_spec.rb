require 'spec_helper_acceptance'

describe 'pdk new task', module_command: true do
  context 'in a new module' do
    include_context 'in a new module', 'new_task'

    describe command('pdk new task foo::bar') do
      its(:stderr) { is_expected.to match(%r{creating .* from template}i) }
      its(:stderr) { is_expected.not_to match(%r{WARN|ERR}) }
      its(:stdout) { is_expected.to match(%r{\A\Z}) }
      its(:exit_status) { is_expected.to eq(0) }
    end

    describe file(File.join('tasks', 'foo', 'bar.sh')) do
      it { is_expected.to be_file }
    end

    describe file(File.join('tasks', 'foo', 'bar.json')) do
      it { is_expected.to be_file }
    end
  end
end
