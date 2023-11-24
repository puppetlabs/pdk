require 'spec_helper_acceptance'
require 'tempfile'

describe 'pdk set config' do
  include_context 'with a fake TTY'

  context 'when run outside of a module' do
    describe command('pdk set config') do
      its(:exit_status) { is_expected.not_to eq 0 }
      its(:stdout) { is_expected.to have_no_output }
      its(:stderr) { is_expected.to match(/Configuration name is required/) }
    end

    context 'with a setting that does not exist' do
      describe command('pdk set config user.module_defaults.mock value') do
        include_context 'with a fake answer file'

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(/user.module_defaults.mock=value/) }
        its(:stderr) { is_expected.to match(/Set initial value of 'user.module_defaults.mock' to 'value'/) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => 'value'

        # We test the literal output here to make sure it outputs pretty JSON instead of minified JSON
        it_behaves_like 'a saved configuration file', "{\n  \"mock\": \"value\"\n}\n"
      end
    end

    context 'with an existing array setting, not forced' do
      describe command('pdk set config user.module_defaults.mock value') do
        include_context 'with a fake answer file', 'mock' => []

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(/user.module_defaults.mock=\["value"\]/) }
        its(:stderr) { is_expected.to match(/Added new value 'value' to 'user.module_defaults.mock'/) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => ['value']
      end
    end

    context 'with an existing non-array setting, not forced' do
      describe command('pdk set config user.module_defaults.mock value') do
        include_context 'with a fake answer file', 'mock' => 1

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(/user.module_defaults.mock=value/) }
        its(:stderr) { is_expected.to match(/Changed existing value of 'user.module_defaults.mock' from '1' to 'value'/) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => 'value'
      end
    end

    context 'with an existing setting, forced' do
      describe command('pdk set config --force user.module_defaults.mock value') do
        include_context 'with a fake answer file', 'mock' => []

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(/user.module_defaults.mock=value/) }
        its(:stderr) { is_expected.to match(/Set initial value of 'user.module_defaults.mock' to 'value'/) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => 'value'
      end
    end

    context 'with an existing setting, forced and an explicit type' do
      describe command('pdk set config --force --type number user.module_defaults.mock 1') do
        include_context 'with a fake answer file', 'mock' => []

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(/user.module_defaults.mock=1/) }
        its(:stderr) { is_expected.to match(/Set initial value of 'user.module_defaults.mock' to '1'/) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => 1
      end
    end

    context 'with an existing setting, forced and an explicit type (--as)' do
      describe command('pdk set config --force --as number user.module_defaults.mock 1') do
        include_context 'with a fake answer file', 'mock' => []

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(/user.module_defaults.mock=1/) }
        its(:stderr) { is_expected.to match(/Set initial value of 'user.module_defaults.mock' to '1'/) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => 1
      end
    end

    context 'with an invalid type' do
      describe command('pdk set config --type invalid_type_name user.module_defaults.mock value') do
        include_context 'with a fake answer file', 'mock' => 'old_value'

        its(:exit_status) { is_expected.not_to eq 0 }
        its(:stdout) { is_expected.to have_no_output }
        its(:stderr) { is_expected.to match(/Unknown type invalid_type_name/) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => 'old_value'
      end
    end
  end
end
