require 'spec_helper_acceptance'

describe 'Basic usage of the CLI' do
  let(:path_to_pdk) do
    if workstation['platform'] =~ /windows/
      '/cygdrive/c/Program\ Files/Puppet\ Labs/DevelopmentKit/bin/pdk.bat'
    else
      '/opt/puppetlabs/sdk/bin/pdk'
    end
  end

  it 'should display help text' do
    on(workstation, "#{path_to_pdk} --help") do |outcome|
      expect(outcome.stdout).to match(/NAME.*USAGE.*DESCRIPTION.*COMMANDS.*OPTIONS/m)
    end
  end
end
