require 'spec_helper_acceptance'

describe 'When pdk is installed by a package', package: true do
  describe command('which pdk') do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match(%r{#{default_installed_bin_dir}/pdk}) }
    its(:stderr) { is_expected.to match(%r{\A\Z}) }
  end
end
