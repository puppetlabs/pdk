require 'spec_helper_acceptance'

describe 'Basic usage of the CLI' do
  it 'should display help text' do
    on(workstation, '/opt/puppetlabs/sdk/bin/pdk --help') do |outcome|
      expect(outcome.stdout).to match /NAME.*USAGE.*DESCRIPTION.*COMMANDS.*OPTIONS/m
    end
  end
end
