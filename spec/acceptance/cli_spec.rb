require 'spec_helper_acceptance'

describe 'Basic usage of the CLI' do
  describe command("#{path_to_pdk} --help") do
    its(:stdout) { is_expected.to match(/NAME.*USAGE.*DESCRIPTION.*COMMANDS.*OPTIONS/m) }
    its(:stderr) { is_expected.to match(/\A\Z/) }
  end
end
